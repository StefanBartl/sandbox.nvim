-- follow_logs streams stdout and stderr through ONE shared vim.system() call,
-- but a container's logs are still two independent byte streams: `vim.system`
-- invokes their callbacks separately, in whatever order the OS delivers
-- data. If both streams fed one shared line-buffer, a partial line from one
-- stream that has not seen its newline yet could get spliced onto an
-- unrelated chunk that arrives on the OTHER stream first -- producing a
-- garbled "line" that never existed in either stream. This pins that each
-- stream's trailing partial line can only ever be completed by more of the
-- SAME stream, across all three engines.

describe("adapters.*.containers.follow_logs stream separation", function()
  local real_system
  local system_calls

  before_each(function()
    system_calls = {}
    real_system = vim.system
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.system = function(cmd, opts, on_exit)
      local call = { cmd = cmd, opts = opts, on_exit = on_exit }
      system_calls[#system_calls + 1] = call
      return {
        kill = function() end,
      }
    end
  end)

  after_each(function()
    vim.system = real_system
  end)

  local ENGINES = { "docker", "podman", "nerdctl" }

  for _, engine in ipairs(ENGINES) do
    it(engine .. ": an interleaved stdout/stderr chunk pair never splices into one line", function()
      local M = require("sandbox.adapters." .. engine .. ".containers.follow_logs")
      local lines = {}
      M.follow_logs("abc123", function(line)
        lines[#lines + 1] = line
      end)

      local call = system_calls[1]
      assert.is_not_nil(call, engine .. ": vim.system was called")

      -- stdout emits a partial line with no newline yet ...
      call.opts.stdout(nil, "foo")
      -- ... then stderr emits a complete, unrelated line before stdout's
      -- own newline ever arrives.
      call.opts.stderr(nil, "bar\n")

      vim.wait(10, function()
        return #lines > 0
      end)

      assert.are.same({ "bar" }, lines, engine .. ": stderr's own complete line, uncorrupted by stdout's partial one")

      -- stdout's own newline now arrives, completing ITS line.
      lines = {}
      call.opts.stdout(nil, "\n")
      vim.wait(10, function()
        return #lines > 0
      end)
      assert.are.same(
        { "foo" },
        lines,
        engine .. ": stdout's own partial line completes intact, not merged with stderr's"
      )
    end)

    it(engine .. ": leftover partial lines on both streams flush separately at exit", function()
      local M = require("sandbox.adapters." .. engine .. ".containers.follow_logs")
      local lines = {}
      local exit_code
      M.follow_logs("abc123", function(line)
        lines[#lines + 1] = line
      end, function(code)
        exit_code = code
      end)

      local call = system_calls[#system_calls]
      call.opts.stdout(nil, "unterminated-out")
      call.opts.stderr(nil, "unterminated-err")
      call.on_exit({ code = 0 })

      vim.wait(10, function()
        return exit_code ~= nil
      end)

      table.sort(lines)
      assert.are.same(
        { "unterminated-err", "unterminated-out" },
        lines,
        engine .. ": both leftovers flushed, neither merged into the other"
      )
      assert.are.equal(0, exit_code)
    end)
  end
end)

-- ERR-01: `vim.system` throws synchronously (uv.spawn ENOENT and friends)
-- rather than reporting a failed spawn through the exit callback, unlike
-- `vim.fn.jobstart`'s adapters which merely return -1. Unguarded, that throw
-- would land between the caller opening its scratch buffer and binding `q`
-- and the BufWipeout kill-handler on it, leaving a stuck, keyless buffer.
describe("adapters.*.containers.follow_logs spawn failure", function()
  local real_system

  before_each(function()
    real_system = vim.system
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.system = function()
      error("uv_spawn: ENOENT: no such file or directory")
    end
  end)

  after_each(function()
    vim.system = real_system
  end)

  local ENGINES = { "docker", "podman", "nerdctl" }

  for _, engine in ipairs(ENGINES) do
    it(engine .. ": a synchronous spawn throw is reported through on_line/on_exit, not raised", function()
      local M = require("sandbox.adapters." .. engine .. ".containers.follow_logs")
      local lines = {}
      local exit_code, exit_seen
      local handle

      local ok = pcall(function()
        handle = M.follow_logs("abc123", function(line)
          lines[#lines + 1] = line
        end, function(code)
          exit_code = code
          exit_seen = true
        end)
      end)

      assert.is_true(ok, engine .. ": follow_logs must not throw when the spawn itself throws")
      assert.is_not_nil(handle, engine .. ": a handle must still come back, so the caller can bind close/BufWipeout")
      assert.is_function(handle.stop)
      assert.has_no.errors(function()
        handle.stop()
      end)

      vim.wait(10, function()
        return exit_seen
      end)
      assert.is_true(exit_seen, engine .. ": on_exit must still run")
      assert.is_nil(exit_code)
      assert.are.equal(1, #lines, engine .. ": on_line must report the failure")
      assert.is_not_nil(lines[1]:find("failed to start", 1, true))
    end)
  end
end)
