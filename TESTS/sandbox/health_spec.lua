-- `:checkhealth sandbox` against a chosen machine: which CLIs are on PATH,
-- which of them answer, whether wsl.exe exists, and which of the three
-- unrelated reasons the hover integration can be absent for.
--
-- `vim.health` is replaced by a recorder *before* `sandbox.health` is
-- required, because the module binds it to an upvalue at load time -- the
-- same load-time-binding rule the adapters follow for `run_argv`. Nothing
-- probes a real daemon: `engine_utils`' two questions about the world are
-- faked at the module's own seam, exactly as `engine_utils_spec` does.
--
-- Note for the next reader: the closing `composer.checkhealth("Sandbox")`
-- call is unconditional, and so is the `require` of lib.nvim that reaches it.
-- That is correct here -- `docs/installation.md` lists lib.nvim as
-- **required** -- even though `notify.lua`, `logger.lua` and `run_argv.lua`
-- each carry a soft-dependency fallback and a comment calling it optional.
-- It is pinned below so the two halves cannot drift apart silently.
---@diagnostic disable: need-check-nil

describe("sandbox.health", function()
  local real_health
  local reports

  --- Load `sandbox.health` against a recorded `vim.health` and a described
  --- machine.
  ---@class HealthMachine
  ---@field engine string|nil  # what resolve_engine_name() answers
  ---@field installed table<string, boolean>  # what is on PATH
  ---@field live table<string, boolean>  # what answers
  ---@field hover any  # config.options.hover
  ---@field hover_installed? boolean
  ---@field hover_registered? boolean

  ---@param opts HealthMachine
  ---@return table module
  local function load_health(opts)
    reports = {}
    local function record(kind)
      return function(msg, advice)
        reports[#reports + 1] = { kind = kind, msg = msg, advice = advice }
      end
    end
    ---@diagnostic disable-next-line: duplicate-set-field, assign-type-mismatch
    vim.health = {
      start = record("start"),
      ok = record("ok"),
      info = record("info"),
      warn = record("warn"),
      error = record("error"),
    }

    package.loaded["sandbox.health"] = nil
    package.loaded["sandbox.config"] = nil
    package.loaded["sandbox.engine_utils"] = nil
    package.loaded["sandbox"] = nil

    local config = require("sandbox.config")
    config.options.hover = opts.hover

    local engine_utils = require("sandbox.engine_utils")
    ---@diagnostic disable-next-line: duplicate-set-field
    engine_utils.is_executable = function(cmd)
      return opts.installed[cmd] == true
    end
    ---@diagnostic disable-next-line: duplicate-set-field
    engine_utils.responds = function(name)
      return opts.live[name] == true
    end

    local sandbox = require("sandbox")
    ---@diagnostic disable-next-line: duplicate-set-field
    sandbox.resolve_engine_name = function()
      return opts.engine
    end

    if opts.hover_installed then
      package.loaded["hover.registry"] = {}
    else
      package.loaded["hover.registry"] = nil
    end
    package.loaded["sandbox.hover"] = {
      registered = function()
        return opts.hover_registered == true
      end,
    }

    package.loaded["lib.nvim.bindings.usercmd.composer"] = {
      checkhealth = function(verb)
        reports[#reports + 1] = { kind = "composer", msg = verb }
      end,
    }

    return require("sandbox.health")
  end

  --- @param kind string
  --- @param needle string
  --- @return table|nil
  local function find(kind, needle)
    for _, r in ipairs(reports) do
      if r.kind == kind and type(r.msg) == "string" and r.msg:find(needle, 1, true) then
        return r
      end
    end
    return nil
  end

  before_each(function()
    real_health = vim.health
  end)

  after_each(function()
    vim.health = real_health
    package.loaded["sandbox.health"] = nil
    package.loaded["sandbox.hover"] = nil
    package.loaded["hover.registry"] = nil
    package.loaded["lib.nvim.bindings.usercmd.composer"] = nil
    package.loaded["sandbox.config"] = nil
    package.loaded["sandbox.engine_utils"] = nil
    package.loaded["sandbox"] = nil
  end)

  -- LUA-01: docs/installation.md declares lib.nvim a hard dependency, so its
  -- absence must be *reported*, not just left to throw wherever the first
  -- unguarded `require("lib.nvim...")` inside an adapter happens to sit.
  --
  -- Stubs `M._lib_nvim_installed` rather than forcing a real `require`
  -- failure through `package.preload`: lib.nvim is genuinely on the rtp in
  -- this test run, and Neovim's Lua loader keeps failing a module name after
  -- one forced failure even once the trap is removed, which would poison
  -- every later test in this same process.
  it("reports lib.nvim missing before anything else, instead of throwing", function()
    local health =
      load_health({ engine = "docker", installed = { docker = true }, live = { docker = true }, hover = true })
    health._lib_nvim_installed = function()
      return false
    end

    local ok = pcall(health.check)

    assert.is_true(ok, "must report, not throw")
    assert.is_not_nil(find("error", "lib.nvim is not installed"))
    -- Nothing after the early return.
    assert.is_nil(find("ok", "Container engine in use"))
    assert.is_nil(find("composer", "Sandbox"))
  end)

  it("stops at the first error when no engine resolves at all", function()
    local health = load_health({ engine = nil, installed = {}, live = {}, hover = true })

    health.check()

    assert.is_not_nil(find("error", "No container engine configured"))
    -- Nothing after the early return: no PATH check, no hover section, and
    -- notably no composer call.
    assert.is_nil(find("ok", "CLI executable found"))
    assert.is_nil(find("composer", "Sandbox"))
  end)

  it("stops at the first error when the engine is not one of the three", function()
    local health = load_health({ engine = "containerd", installed = {}, live = {}, hover = true })

    health.check()

    assert.is_not_nil(find("error", "Invalid container engine configured: containerd"))
    assert.is_nil(find("ok", "CLI executable found"))
  end)

  it("reports a healthy machine", function()
    local health = load_health({
      engine = "docker",
      installed = { docker = true, wsl = true },
      live = { docker = true },
      hover = true,
      hover_installed = true,
      hover_registered = true,
    })

    health.check()

    assert.is_not_nil(find("ok", "Container engine in use: docker"))
    assert.is_not_nil(find("ok", "docker CLI executable found"))
    assert.is_not_nil(find("ok", "docker answers"))
    assert.is_not_nil(find("ok", "WSL executable found"))
    assert.is_not_nil(find("ok", "hover.nvim image preview registered"))
    assert.is_nil(find("error", "does not answer"))
  end)

  it("reports a missing CLI as an error and still goes on", function()
    local health = load_health({ engine = "podman", installed = {}, live = {}, hover = false })

    health.check()

    assert.is_not_nil(find("error", "podman CLI executable not found in PATH"))
    -- The section after it still runs: a missing CLI is not a reason to stop
    -- reporting.
    assert.is_not_nil(find("error", "does not answer"))
  end)

  it("names the engines that DO answer when the configured one does not", function()
    local health = load_health({
      engine = "podman",
      installed = { podman = true, docker = true, nerdctl = true },
      live = { docker = true, nerdctl = true },
      hover = true,
    })

    health.check()

    local report = find("error", "podman does not answer")
    assert.is_not_nil(report)
    assert.is_truthy(table.concat(report.advice, " "):find("docker, nerdctl", 1, true))
    -- The advice has to be actionable, i.e. name the command to run.
    assert.is_truthy(table.concat(report.advice, " "):find(":Sandbox engine set docker", 1, true))
  end)

  it("asks about the daemon when nothing on the machine answers", function()
    local health = load_health({
      engine = "docker",
      installed = { docker = true, podman = true },
      live = {},
      hover = true,
    })

    health.check()

    local report = find("error", "is its daemon running?")
    assert.is_not_nil(report)
    assert.is_truthy(table.concat(report.advice, " "):find(":Sandbox engine reset", 1, true))
  end)

  it("treats a missing wsl.exe as information, not a problem", function()
    local health =
      load_health({ engine = "docker", installed = { docker = true }, live = { docker = true }, hover = true })

    health.check()

    assert.is_not_nil(find("info", "WSL not found in PATH"))
    assert.is_nil(find("error", "WSL"))
  end)

  -- ERR-22: an invalid refresh_interval degrades to its default (auto-refresh
  -- off) rather than aborting the plugin, and that degradation must be
  -- visible here -- setup_autorefresh itself has no other way to say which
  -- config key it silently ignored.
  it("warns about a non-number refresh_interval", function()
    local health =
      load_health({ engine = "docker", installed = { docker = true }, live = { docker = true }, hover = true })
    require("sandbox.config").options.refresh_interval = "2000"

    health.check()

    assert.is_not_nil(find("warn", "refresh_interval is not a number"))
  end)

  it("says nothing about refresh_interval when it is a number or nil", function()
    for _, value in ipairs({ nil, 0, 2000 }) do
      local health =
        load_health({ engine = "docker", installed = { docker = true }, live = { docker = true }, hover = true })
      require("sandbox.config").options.refresh_interval = value

      health.check()

      assert.is_nil(find("warn", "refresh_interval"), "value " .. tostring(value))
    end
  end)

  describe("the hover section names which of the three reasons applies", function()
    it("opts.hover = false", function()
      local health = load_health({
        engine = "docker",
        installed = { docker = true },
        live = { docker = true },
        hover = false,
        hover_installed = true,
        hover_registered = true,
      })

      health.check()

      assert.is_not_nil(find("info", "Hover integration disabled"))
      assert.is_nil(find("ok", "hover.nvim image preview registered"))
    end)

    it("hover.nvim not installed", function()
      local health = load_health({
        engine = "docker",
        installed = { docker = true },
        live = { docker = true },
        hover = true,
        hover_installed = false,
      })

      health.check()

      assert.is_not_nil(find("info", "hover.nvim not installed"))
    end)

    it("hover.nvim installed but it ignores on_request", function()
      local health = load_health({
        engine = "docker",
        installed = { docker = true },
        live = { docker = true },
        hover = true,
        hover_installed = true,
        hover_registered = false,
      })

      health.check()

      local report = find("warn", "does not support request-only contributions")
      assert.is_not_nil(report)
      assert.are.same({ "Update hover.nvim" }, report.advice)
    end)
  end)

  it("hands the report over to lib.nvim's usercmd composer last", function()
    local health =
      load_health({ engine = "docker", installed = { docker = true }, live = { docker = true }, hover = true })

    health.check()

    assert.are.equal("composer", reports[#reports].kind)
    assert.are.equal("Sandbox", reports[#reports].msg)
  end)

  it("needs lib.nvim -- the closing composer call is not guarded", function()
    -- Not a defect: lib.nvim is a **required** dependency
    -- (docs/installation.md). Pinned because three other modules
    -- (notify/logger/run_argv) carry a "lib.nvim stays an optional
    -- dependency" fallback, and a reader who believes that comment would
    -- expect `:checkhealth sandbox` to degrade rather than raise.
    local health =
      load_health({ engine = "docker", installed = { docker = true }, live = { docker = true }, hover = true })
    package.loaded["lib.nvim.bindings.usercmd.composer"] = nil
    package.preload["lib.nvim.bindings.usercmd.composer"] = function()
      error("module 'lib.nvim.bindings.usercmd.composer' not found")
    end

    local ok = pcall(health.check)
    package.preload["lib.nvim.bindings.usercmd.composer"] = nil

    assert.is_false(ok)
    -- Everything sandbox.nvim itself reports was already reported, though:
    -- the raise happens on the last line.
    assert.is_not_nil(find("ok", "docker answers"))
  end)
end)
