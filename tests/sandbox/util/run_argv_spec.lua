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

  --- The progress indicator is a soft dependency, so these only assert
  --- anything when lib.nvim is actually on the rtp (LIB_NVIM_PATH set). The
  --- "statusline" style is what makes this testable at all: it is headless and
  --- keeps its text in a readable registry, so there is no window or
  --- notification to intercept.
  describe("progress indicator", function()
    local ok_progress, statusline = pcall(require, "lib.nvim.progress.styles.statusline")
    local config = require("sandbox.config")
    local prev_style

    before_each(function()
      prev_style = config.options.progress_style
      config.options.progress_style = "statusline"
    end)

    after_each(function()
      config.options.progress_style = prev_style
    end)

    it("publishes the operation while it runs and clears it afterwards", function()
      if not ok_progress then
        return -- lib.nvim absent: run_async_captured is expected to be a no-op here
      end

      -- Long enough to outlive the 150ms delay guard, so the handle actually
      -- becomes visible rather than being suppressed as a fast operation.
      local sleep_cmd = vim.fn.has("win32") == 1
        and { "cmd", "/c", "ping -n 2 127.0.0.1 >NUL" }
        or { "sleep", "1" }

      local finished = false
      run_argv.run_async_captured(sleep_cmd, function() finished = true end)

      vim.wait(1000, function() return #statusline.active() > 0 end, 10)
      local active = statusline.active()
      assert.is_true(#active > 0)
      assert.is_not_nil(active[1]:find("sandbox.nvim", 1, true))

      vim.wait(5000, function() return finished end, 10)
      -- finish() runs in the same tick as on_done, so the registry is already
      -- drained by the time the callback has fired.
      assert.equals(0, #statusline.active())
    end)

    it("does not leave a stale entry behind when the job is stopped", function()
      if not ok_progress then
        return
      end

      local sleep_cmd = vim.fn.has("win32") == 1
        and { "cmd", "/c", "ping -n 5 127.0.0.1 >NUL" }
        or { "sleep", "5" }

      local finished = false
      local handle = run_argv.run_async_captured(sleep_cmd, function() finished = true end)

      vim.wait(1000, function() return #statusline.active() > 0 end, 10)
      handle.stop()

      vim.wait(5000, function() return finished end, 10)
      assert.is_true(finished)
      assert.equals(0, #statusline.active())
    end)
  end)
end)
