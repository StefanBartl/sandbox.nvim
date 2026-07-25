--- Unlike the adapter specs (which fake this module out), these exercise
--- util/run_argv.lua itself against a real, trivial, always-available
--- command -- there's no docker/podman dependency to fake here, this *is*
--- the shell-out primitive.

describe("util.run_argv", function()
  local run_argv = require("sandbox.util.run_argv")
  local echo_cmd = vim.fn.has("win32") == 1 and { "cmd", "/c", "echo hello" } or { "echo", "hello" }

  it("run_blocking_captured returns ok=true and captures stdout", function()
    local ok, output = run_argv.run_blocking_captured(echo_cmd)

    assert.is_true(ok)
    assert.is_not_nil(output:find("hello", 1, true))
  end)

  it("run_blocking_captured fails (returns ok=false, or raises) for a nonexistent binary", function()
    -- lib.nvim's vim.system-backed path currently raises ENOENT here rather
    -- than returning ok=false (a gap worth fixing upstream in lib.nvim,
    -- separate from this plugin); accept either outcome so this test
    -- documents the real behavior instead of asserting a false guarantee.
    local pcall_ok, ok = pcall(run_argv.run_blocking_captured, { "sandbox-nvim-definitely-not-a-real-binary" })

    assert.is_true(not pcall_ok or ok == false)
  end)

  it("run_async_captured does not block and eventually calls on_done", function()
    local done_ok, done_output
    local handle = run_argv.run_async_captured(echo_cmd, function(ok, output)
      done_ok, done_output = ok, output
    end)

    assert.is_function(handle.stop)
    -- on_done hasn't necessarily fired synchronously -- give the event loop a turn.
    vim.wait(2000, function() return done_ok ~= nil end, 10)

    assert.is_true(done_ok)
    assert.is_not_nil(done_output:find("hello", 1, true))
  end)
end)
