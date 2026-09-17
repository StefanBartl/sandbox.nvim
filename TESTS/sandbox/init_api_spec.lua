-- The public surface other plugins and the whole command layer go through:
-- `setup`, `get_engine`, `get_compose_engine`, and the one step of
-- `resolve_engine_name` that `init_spec` does not cover -- the fall-through to
-- the liveness probe, which only happens when the engine was *detected*
-- rather than named.
--
-- `init_spec.lua` next to this file covers the precedence chain
-- (vim.g > .sandboxrc > configured). This one covers what happens at the end
-- of that chain and what the two getters do with a name they cannot map.
--
-- No probe is ever run: `engine_utils`' two questions are faked at the
-- module's own seam, so nothing here starts a process.
---@diagnostic disable: need-check-nil

describe("sandbox public API", function()
  local notices

  --- @return table sandbox, table engine_utils
  local function fresh()
    package.loaded["sandbox"] = nil
    package.loaded["sandbox.config"] = nil
    package.loaded["sandbox.engine_utils"] = nil
    package.loaded["sandbox.notify"] = nil
    package.loaded["sandbox.util.project_config"] = nil

    notices = {}
    package.loaded["sandbox.notify"] = {
      info = function(msg)
        notices[#notices + 1] = { level = "info", msg = msg }
      end,
      warn = function(msg)
        notices[#notices + 1] = { level = "warn", msg = msg }
      end,
      error = function(msg)
        notices[#notices + 1] = { level = "error", msg = msg }
      end,
    }

    local engine_utils = require("sandbox.engine_utils")
    ---@diagnostic disable-next-line: duplicate-set-field
    engine_utils.get_engine = function()
      return "docker"
    end
    ---@diagnostic disable-next-line: duplicate-set-field
    engine_utils.get_live_engine = function()
      return "nerdctl"
    end
    -- `project_config` reads `.sandboxrc` from the cwd; the suite runs from
    -- the repo root, which has none, but say so explicitly rather than
    -- depend on that.
    package.loaded["sandbox.util.project_config"] = {
      read_engine_override = function()
        return nil
      end,
    }

    return require("sandbox"), engine_utils
  end

  before_each(function()
    vim.g.sandbox_engine = nil
  end)

  after_each(function()
    vim.g.sandbox_engine = nil
    package.loaded["sandbox"] = nil
    package.loaded["sandbox.config"] = nil
    package.loaded["sandbox.engine_utils"] = nil
    package.loaded["sandbox.notify"] = nil
    package.loaded["sandbox.util.project_config"] = nil
    package.loaded["sandbox.hover"] = nil
  end)

  describe("resolve_engine_name", function()
    it("asks which engine is alive when the engine was detected, not named", function()
      local sandbox = fresh()
      sandbox.setup({})

      -- `get_engine()` (cheap, PATH-only) filled config.options.engine with
      -- "docker" at setup time; because nobody *named* it, resolution goes
      -- to the live probe, which prefers "nerdctl" here.
      assert.are.equal("nerdctl", sandbox.resolve_engine_name())
    end)

    it("does not ask when the engine was named", function()
      local sandbox = fresh()
      sandbox.setup({ engine = "podman" })

      assert.are.equal("podman", sandbox.resolve_engine_name())
    end)
  end)

  describe("get_engine / get_compose_engine", function()
    it("maps each engine name to its own adapter pair", function()
      local sandbox = fresh()
      for _, name in ipairs({ "docker", "podman", "nerdctl" }) do
        sandbox.setup({ engine = name })

        assert.are.equal(require("sandbox.adapters." .. name .. ".engine"), sandbox.get_engine())
        assert.are.equal(require("sandbox.adapters." .. name .. ".compose_engine"), sandbox.get_compose_engine())
      end
    end)

    it("reports an unmappable name instead of returning something half-usable", function()
      local sandbox = fresh()
      sandbox.setup({ engine = "docker" })
      vim.g.sandbox_engine = "containerd"

      assert.is_nil(sandbox.get_engine())
      assert.is_nil(sandbox.get_compose_engine())
      assert.are.equal(2, #notices)
      assert.are.equal("error", notices[1].level)
      assert.is_truthy(notices[1].msg:find("Invalid engine: containerd", 1, true))
    end)

    it("stringifies a nil engine name in the error rather than concatenating nil", function()
      local sandbox = fresh()
      package.loaded["sandbox.config"].engine_named = true
      package.loaded["sandbox.config"].options.engine = nil

      assert.is_nil(sandbox.get_engine())
      assert.is_truthy(notices[1].msg:find("Invalid engine: nil", 1, true))
    end)
  end)

  describe("setup", function()
    it("registers the hover contribution by default", function()
      local sandbox = fresh()
      local registered = 0
      package.loaded["sandbox.hover"] = {
        setup = function()
          registered = registered + 1
        end,
      }

      sandbox.setup({ engine = "docker" })

      assert.are.equal(1, registered)
    end)

    it("leaves hover alone when hover = false", function()
      local sandbox = fresh()
      local registered = 0
      package.loaded["sandbox.hover"] = {
        setup = function()
          registered = registered + 1
        end,
      }

      sandbox.setup({ engine = "docker", hover = false })

      assert.are.equal(0, registered)
    end)

    it("passes its options through to config", function()
      local sandbox = fresh()
      package.loaded["sandbox.hover"] = { setup = function() end }

      sandbox.setup({ engine = "podman", default_shell = "bash" })

      assert.are.equal("bash", require("sandbox.config").options.default_shell)
    end)
  end)
end)
