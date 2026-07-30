-- Docker Adapter: Function to prune all stopped containers

local run_argv = require("sandbox.util.run_argv")

local M = {}

--- Remove all stopped containers without blocking the UI thread.
--- @param on_done? fun(ok: boolean, err: string|nil)
--- @return table handle with a `:stop()` method
function M.prune_containers(on_done)
  return run_argv.run_async_captured({ "docker", "container", "prune", "-f" }, function(ok, output, code)
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
