describe("bindings.usrcmds.registry_commands.login", function()
  local queue
  local notified

  local function record(level)
    return function(msg, ctx)
      table.insert(notified, { level = level, msg = msg, ctx = ctx })
    end
  end

  before_each(function()
    notified = {}
    package.loaded["sandbox"] = { get_engine = function()
      return { login_registry = function() end }
    end }
    package.loaded["sandbox.notify"] = {
      warn = record("warn"),
      error = record("error"),
      info = record("info"),
    }
    -- Mirrors kit.input's real on_submit/on_cancel contract (lib.nvim's
    -- lua/lib/nvim/ui/kit/input.lua): each call pops the next queued answer
    -- and fires the matching callback immediately. registry_commands.lua
    -- calls kit.input twice in sequence (username, then nested password), so
    -- one shared queue -- popped in call order -- covers both fields.
    package.loaded["lib.nvim.ui.kit"] = {
      input = function(opts)
        local item = table.remove(queue, 1)
        if item.cancel then
          if opts.on_cancel then
            opts.on_cancel()
          end
        else
          if opts.on_submit then
            opts.on_submit(item.value)
          end
        end
      end,
    }
    package.loaded["sandbox.bindings.usrcmds.registry_commands"] = nil
  end)

  after_each(function()
    package.loaded["lib.nvim.ui.kit"] = nil
    package.loaded["sandbox.notify"] = nil
    package.loaded["sandbox.core.usecases.registry.login"] = nil
    package.loaded["sandbox.bindings.usrcmds.registry_commands"] = nil
  end)

  it("logs in with username and masked password submitted", function()
    local captured
    package.loaded["sandbox.core.usecases.registry.login"] = function(engine, username, password, registry)
      captured = { engine = engine, username = username, password = password, registry = registry }
      return true
    end
    local rc = require("sandbox.bindings.usrcmds.registry_commands")

    queue = {
      { value = "alice" },
      { value = "hunter2" },
    }
    rc.login("registry.example.com")

    assert.are.equal("alice", captured.username)
    assert.are.equal("hunter2", captured.password)
    assert.are.equal("registry.example.com", captured.registry)
    assert.are.equal("info", notified[1].level)
  end)

  it("the password field is asked with secret = true", function()
    package.loaded["sandbox.core.usecases.registry.login"] = function()
      return true
    end
    local seen_opts = {}
    package.loaded["lib.nvim.ui.kit"] = {
      input = function(opts)
        table.insert(seen_opts, opts)
        local item = table.remove(queue, 1)
        if item.cancel then
          if opts.on_cancel then
            opts.on_cancel()
          end
        else
          if opts.on_submit then
            opts.on_submit(item.value)
          end
        end
      end,
    }
    local rc = require("sandbox.bindings.usrcmds.registry_commands")

    queue = { { value = "alice" }, { value = "hunter2" } }
    rc.login()

    assert.is_falsy(seen_opts[1].secret)
    assert.is_true(seen_opts[2].secret)
  end)

  it("empty username cancels before the password is ever asked", function()
    local usecase_called = false
    package.loaded["sandbox.core.usecases.registry.login"] = function()
      usecase_called = true
      return true
    end
    local rc = require("sandbox.bindings.usrcmds.registry_commands")

    queue = { { value = "" } }
    rc.login()

    assert.is_false(usecase_called)
    assert.are.equal("warn", notified[1].level)
    assert.are.equal(0, #queue) -- password was never asked
  end)

  it("<Esc> on the password field cancels without running", function()
    local usecase_called = false
    package.loaded["sandbox.core.usecases.registry.login"] = function()
      usecase_called = true
      return true
    end
    local rc = require("sandbox.bindings.usrcmds.registry_commands")

    queue = { { value = "alice" }, { cancel = true } }
    rc.login()

    assert.is_false(usecase_called)
    assert.are.equal("warn", notified[#notified].level)
  end)

  it("an empty password (bare <CR>) cancels without running", function()
    local usecase_called = false
    package.loaded["sandbox.core.usecases.registry.login"] = function()
      usecase_called = true
      return true
    end
    local rc = require("sandbox.bindings.usrcmds.registry_commands")

    queue = { { value = "alice" }, { value = "" } }
    rc.login()

    assert.is_false(usecase_called)
    assert.are.equal("warn", notified[#notified].level)
  end)

  it("reports a usecase failure via notify.error", function()
    package.loaded["sandbox.core.usecases.registry.login"] = function()
      return false, "cannot connect to the Docker daemon"
    end
    local rc = require("sandbox.bindings.usrcmds.registry_commands")

    queue = { { value = "alice" }, { value = "hunter2" } }
    rc.login()

    assert.are.equal("error", notified[#notified].level)
  end)
end)
