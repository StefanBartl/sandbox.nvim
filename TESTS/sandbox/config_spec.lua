-- `config.setup`'s merge semantics, and the one flag the engine resolution
-- hangs off: `engine_named`.
--
-- The distinction that flag records is load-bearing rather than cosmetic --
-- a *named* engine is an instruction and is never second-guessed, while a
-- *detected* one is a guess that `resolve_engine_name` checks against a live
-- probe. Once `options.engine` is filled in, the two are indistinguishable
-- without it.
--
-- Detection is faked here. The real `engine_utils.get_engine()` only reads
-- PATH (no process start), but a spec that let it run would report whatever
-- happens to be installed on the machine running the suite.
---@diagnostic disable: need-check-nil

describe("sandbox.config", function()
  --- @param detected string
  --- @return table config, table calls
  local function fresh(detected)
    package.loaded["sandbox.config"] = nil
    package.loaded["sandbox.engine_utils"] = nil
    local calls = { detections = 0 }
    local engine_utils = require("sandbox.engine_utils")
    ---@diagnostic disable-next-line: duplicate-set-field
    engine_utils.get_engine = function()
      calls.detections = calls.detections + 1
      return detected
    end
    return require("sandbox.config"), calls
  end

  after_each(function()
    package.loaded["sandbox.config"] = nil
    package.loaded["sandbox.engine_utils"] = nil
  end)

  it("ships every default the rest of the plugin reads", function()
    local config = fresh("docker")

    -- Spot-checked rather than compared wholesale: this list is the set of
    -- keys other modules index into, so a rename that misses one site fails
    -- here instead of at a nil concatenation on a user's machine.
    assert.is_true(config.options.confirm_destructive)
    assert.are.equal("sh", config.options.default_shell)
    assert.are.equal("auto", config.options.progress_style)
    assert.are.equal(200, config.options.max_error_length)
    assert.are.equal(3000, config.options.status_cache_ttl_ms)
    assert.are.equal(4000, config.options.completion_cache_ttl_ms)
    assert.are.equal("left", config.options.list_split)
    assert.is_true(config.options.hover)
    assert.is_true(config.options.menu.enable)
    assert.is_nil(config.options.engine)
  end)

  it("detects the engine when setup names none, and records it as not named", function()
    local config, calls = fresh("nerdctl")

    config.setup({})

    assert.are.equal("nerdctl", config.options.engine)
    assert.is_false(config.engine_named)
    assert.are.equal(1, calls.detections)
  end)

  it("detects nothing when setup names an engine", function()
    local config, calls = fresh("nerdctl")

    config.setup({ engine = "podman" })

    assert.are.equal("podman", config.options.engine)
    assert.is_true(config.engine_named)
    assert.are.equal(0, calls.detections)
  end)

  it("tolerates setup() with no argument at all", function()
    local config = fresh("docker")

    config.setup()

    assert.are.equal("docker", config.options.engine)
  end)

  it("merges nested tables deeply instead of replacing them", function()
    local config = fresh("docker")

    config.setup({ menu = { enable = false }, keymaps = { containers = { start = "S" } } })

    assert.is_false(config.options.menu.enable)
    assert.are.equal("S", config.options.keymaps.containers.start)
    -- untouched siblings survive
    assert.are.equal("sh", config.options.default_shell)
    assert.are.equal(200, config.options.max_error_length)
  end)

  -- LUA-87: a second call must not accumulate onto whatever the first call
  -- already wrote into `M.options` -- that includes the auto-detected
  -- `engine`, and accumulating it corrupts `engine_named` (see the test
  -- below). Each call starts from a fresh copy of the defaults instead.
  it("resets to defaults on a second call rather than accumulating", function()
    local config = fresh("docker")

    config.setup({ default_shell = "bash" })
    config.setup({ max_error_length = 50 })

    assert.are.equal("sh", config.options.default_shell, "must not survive from the first call")
    assert.are.equal(50, config.options.max_error_length)
  end)

  it("does not let a previous call's detected engine masquerade as named on a later call", function()
    local config = fresh("nerdctl")

    config.setup({})
    config.setup({})

    assert.are.equal("nerdctl", config.options.engine)
    assert.is_false(config.engine_named, "neither call named an engine, so this must stay a guess")
  end)

  it("never writes through to the DEFAULTS module", function()
    -- `M.options` starts as a deepcopy, so a user's setup() (or a view
    -- mutating options) cannot poison the defaults for a later reload.
    local config = fresh("docker")
    local defaults = require("sandbox.config.DEFAULTS")

    config.setup({ menu = { enable = false }, default_shell = "zsh" })
    config.options.list_split = "right"

    assert.is_true(defaults.menu.enable)
    assert.are.equal("sh", defaults.default_shell)
    assert.are.equal("left", defaults.list_split)
  end)

  it("lets setup(false) through for the two opt-out keys", function()
    local config = fresh("docker")

    config.setup({ hover = false, keymaps = false, confirm_destructive = false })

    assert.is_false(config.options.hover)
    assert.is_false(config.options.keymaps)
    assert.is_false(config.options.confirm_destructive)
  end)

  describe("ERR-50: unknown config keys", function()
    it("rejects an unknown top-level key instead of keeping it as a dead field", function()
      local config = fresh("docker")

      config.setup({ nonexistent_option = 5 })

      assert.is_nil(config.options.nonexistent_option)
      assert.are.equal(1, #config.issues)
      assert.is_not_nil(config.issues[1]:find("nonexistent_option", 1, true))
    end)

    it("hints the nearest known key for a close-but-wrong name", function()
      local config = fresh("docker")

      config.setup({ lits_size = 50 })

      assert.is_nil(config.options.lits_size)
      assert.is_not_nil(config.issues[1]:find("did you mean 'list_size'", 1, true), config.issues[1])
    end)

    it("checks nested keys by full dotted path, siblings still apply", function()
      local config = fresh("docker")

      config.setup({ menu = { enalbe = false } })

      assert.is_nil(config.options.menu.enalbe)
      -- the real key keeps its default: the typo did not survive to override it
      assert.is_true(config.options.menu.enable)
      assert.are.equal(1, #config.issues)
      assert.is_not_nil(config.issues[1]:find("menu.enalbe", 1, true), config.issues[1])
    end)

    it("rejects a non-table value for a table-shaped section instead of replacing it wholesale", function()
      local config = fresh("docker")

      config.setup({ menu = "off" })

      assert.is_true(config.options.menu.enable, "must keep the section's real default")
      assert.are.equal(1, #config.issues)
      assert.is_not_nil(config.issues[1]:find("'menu' must be a table", 1, true), config.issues[1])
    end)

    -- The whole point of hand-authoring KNOWN from @types/init.lua instead of
    -- deriving it from `pairs(DEFAULTS)`: these four keys all default to
    -- `nil` in DEFAULTS.lua, so a Lua table literal never creates a key for
    -- them there, and `pairs(DEFAULTS)` never sees them. A validator built
    -- from that alone would misreport every one of them as unknown the
    -- moment a user actually set it -- confirmed here does not happen.
    it("does not flag a nil-defaulting key as unknown when the user sets it", function()
      local config = fresh("docker")

      config.setup({
        engine = "podman",
        refresh_interval = 2000,
        list_size = 50,
        keymaps = { containers = { start = "S" } },
      })

      assert.are.equal(0, #config.issues)
      assert.are.equal("podman", config.options.engine)
      assert.are.equal(2000, config.options.refresh_interval)
      assert.are.equal(50, config.options.list_size)
      assert.are.equal("S", config.options.keymaps.containers.start)
    end)

    -- `keymaps.<kind>` is keyed by arbitrary action names (slugified view
    -- descriptions), not a fixed schema this validator knows -- those are
    -- validated by `lib.nvim.bindings.keymap`'s registry instead. This
    -- validator must leave the whole sub-tree alone rather than trying (and
    -- failing) to check it.
    it("does not recurse into keymaps looking for unknown action names", function()
      local config = fresh("docker")

      config.setup({ keymaps = { containers = { totally_made_up_action = "X" } } })

      assert.are.equal(0, #config.issues)
      assert.are.equal("X", config.options.keymaps.containers.totally_made_up_action)
    end)

    it("resets issues to empty on a later, clean call", function()
      local config = fresh("docker")

      config.setup({ nonexistent_option = 5 })
      assert.are.equal(1, #config.issues)

      config.setup({ default_shell = "bash" })

      assert.are.equal(0, #config.issues)
    end)

    it("treats a non-table opts the same as no opts, without throwing", function()
      local config = fresh("docker")

      local ok = pcall(config.setup, "not-a-table")

      assert.is_true(ok)
      assert.are.equal(0, #config.issues)
      assert.are.equal("sh", config.options.default_shell)
    end)
  end)
end)
