--- Test helper: stub `sandbox.util.run_argv` via `package.preload` so
--- adapter functions can be exercised without shelling out to a real
--- docker/podman/nerdctl/wsl binary. Records every argv call (and stdin
--- input, for the registry login test) and lets a test control the
--- simulated result.
---
--- Adapters cache `run_argv` as a `local` at `require()` time, so the
--- module under test must be required (or re-required, via
--- `package.loaded[name] = nil`) AFTER `install()` for the fake to apply.

local M = {}

---@class FakeRunArgv.Call
---@field cmd string[]
---@field input string|nil

---@class FakeRunArgv.State
---@field calls FakeRunArgv.Call[]

--- @param opts? { ok?: boolean, output?: string, code?: integer, on_call?: fun(cmd: string[], input: string|nil) }
--- @return FakeRunArgv.State
function M.install(opts)
  opts = opts or {}
  local ok = opts.ok
  if ok == nil then
    ok = true
  end
  local output = opts.output or ""
  -- Mirrors the real runner's third callback argument. Adapters fall back to
  -- "exit code N" when a failing command wrote nothing to stderr, so a fake
  -- that omitted this would make them concatenate nil.
  local code = opts.code or (ok and 0 or 1)

  ---@type FakeRunArgv.State
  local state = { calls = {} }

  local function record(cmd, input)
    state.calls[#state.calls + 1] = { cmd = cmd, input = input }
    if opts.on_call then
      opts.on_call(cmd, input)
    end
  end

  package.loaded["sandbox.util.run_argv"] = nil
  package.preload["sandbox.util.run_argv"] = function()
    return {
      run_blocking_captured = function(cmd, input)
        record(cmd, input)
        return ok, output
      end,
      run_async_captured = function(cmd, on_done)
        record(cmd, nil)
        on_done(ok, output, code)
        return { stop = function() end }
      end,
    }
  end

  return state
end

--- Undo `install()` and drop the fake from the module cache, so a later
--- `require("sandbox.util.run_argv")` in the same process gets the real thing.
function M.reset()
  package.preload["sandbox.util.run_argv"] = nil
  package.loaded["sandbox.util.run_argv"] = nil
end

--- Drop cached modules so their next `require()` re-runs top-level code
--- (picking up whatever fake is currently installed). Call before
--- `require()`-ing the module under test in each test case.
---@param names string[]
function M.reload(names)
  for _, name in ipairs(names) do
    package.loaded[name] = nil
  end
end

return M
