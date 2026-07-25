-- Nerdctl Adapter: Function to push an image to a remote registry

local run_argv = require("sandbox.util.run_argv")

local M = {}

--- Push an image to a remote registry without blocking the UI thread.
--- @param name string: Name of the image to push (repository[:tag])
--- @param on_done fun(ok: boolean, err: string|nil)
--- @return table handle with a `:stop()` method
function M.push_image(name, on_done)
  return run_argv.run_async_captured({ "nerdctl", "push", name }, function(ok, output)
    on_done(ok, ok and nil or output)
  end)
end

return M
