---@module 'sandbox.adapters.podman.compose.down'
--- Podman Adapter: Stop and remove a compose project

local run_argv = require("sandbox.util.run_argv")

local M = {}

--- @param file string path to the compose file
--- @param on_done? fun(ok: boolean, err: string|nil)
--- @return table handle with a `:stop()` method
function M.down(file, on_done)
  return run_argv.run_async_captured({ "podman", "compose", "-f", file, "down" }, function(ok, output, code)
    if not on_done then
      return
    end
    if ok then
      -- Not `ok and nil or ...`: in Lua that idiom collapses when the middle
      -- operand is nil, so it would hand the captured output back as an error
      -- on every successful run.
      on_done(true, nil)
      return
    end
    output = vim.trim(output or "")
    on_done(false, output ~= "" and output or ("exit code " .. code))
  end)
end

return M
