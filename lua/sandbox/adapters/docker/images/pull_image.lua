-- Docker Adapter: Function to pull an image

local run_argv = require("sandbox.util.run_argv")

local M = {}

--- Pull an image from a remote registry without blocking the UI thread.
--- @param name string: Name of the image to pull
--- @param on_done fun(ok: boolean, err: string|nil)
--- @return table handle with a `:stop()` method
function M.pull_image(name, on_done)
  return run_argv.run_async_captured({ "docker", "pull", name }, function(ok, output)
    on_done(ok, ok and nil or output)
  end)
end

return M
