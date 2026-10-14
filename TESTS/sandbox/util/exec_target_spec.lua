-- `sandbox.util.exec_target`: `exec_target = "terminal"` hands the exec argv to terminal.nvim's
-- `run` as a direct job; every other case leaves the adapter to open its split as before.
-- terminal.nvim is not on this suite's runtimepath (a soft dependency), so a fake `terminal`
-- module is injected where it is wanted.

describe("sandbox.util.exec_target", function()
  local exec_target = require("sandbox.util.exec_target")
  local config = require("sandbox.config")
  local real_terminal, real_target, real_notify
  local warnings

  before_each(function()
    real_terminal = package.loaded["terminal"]
    real_target = config.options.exec_target
    real_notify = package.loaded["sandbox.notify"]
    warnings = {}
    package.loaded["sandbox.notify"] = {
      warn = function(msg)
        warnings[#warnings + 1] = msg
      end,
    }
    -- the "warn once" latch is module state
    package.loaded["sandbox.util.exec_target"] = nil
    exec_target = require("sandbox.util.exec_target")
  end)

  after_each(function()
    package.loaded["terminal"] = real_terminal
    config.options.exec_target = real_target
    package.loaded["sandbox.notify"] = real_notify
  end)

  local ARGS = { "docker", "exec", "-it", "abc", "sh" }

  it("does nothing by default: the adapter opens its split", function()
    config.options.exec_target = "split"
    package.loaded["terminal"] = {
      run = function()
        error("must not be called")
      end,
    }
    assert.is_false(exec_target.open(ARGS, "abc"))
  end)

  it("hands the argv to terminal.run as a direct, named job", function()
    config.options.exec_target = "terminal"
    local got
    package.loaded["terminal"] = {
      run = function(argv, opts)
        got = { argv = argv, opts = opts }
        return true
      end,
    }
    assert.is_true(exec_target.open(ARGS, "abc"))
    assert.are.same(ARGS, got.argv)
    assert.are.same({ direct = true, name = "sandbox:abc", close = "never" }, got.opts)
  end)

  it("falls back to the split with one warning when terminal.nvim is missing", function()
    config.options.exec_target = "terminal"
    package.loaded["terminal"] = nil
    local real_require = require
    ---@diagnostic disable-next-line: duplicate-set-field
    _G.require = function(name)
      if name == "terminal" then
        error("module 'terminal' not found")
      end
      return real_require(name)
    end
    local first = exec_target.open(ARGS, "abc")
    local second = exec_target.open(ARGS, "abc")
    _G.require = real_require
    assert.is_false(first)
    assert.is_false(second)
    assert.are.equal(1, #warnings, "reported once, not on every exec")
  end)

  it("falls back and says why when terminal.run refuses", function()
    config.options.exec_target = "terminal"
    package.loaded["terminal"] = {
      run = function()
        return false, "no backend"
      end,
    }
    assert.is_false(exec_target.open(ARGS, "abc"))
    assert.are.equal(1, #warnings)
    assert.is_truthy(warnings[1]:find("no backend", 1, true))
  end)

  for _, engine in ipairs({ "docker", "podman", "nerdctl" }) do
    it(engine .. ": exec_in_container opens no split when the terminal takes the session", function()
      config.options.exec_target = "terminal"
      local ran
      package.loaded["terminal"] = {
        run = function(argv)
          ran = argv
          return true
        end,
      }
      package.loaded["sandbox.util.exec_target"] = exec_target
      local real_cmd = vim.cmd
      local opened_split = false
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.cmd = function()
        opened_split = true
      end
      local adapter = require("sandbox.adapters." .. engine .. ".containers.exec_in_container")
      adapter.exec_in_container("abc", { "sh" }, "/app")
      vim.cmd = real_cmd
      assert.are.same({ engine, "exec", "-it", "-w", "/app", "abc", "sh" }, ran)
      assert.is_false(opened_split)
    end)
  end
end)
