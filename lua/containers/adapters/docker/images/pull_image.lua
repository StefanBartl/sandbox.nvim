-- Docker Adapter: Function to pull an image

local run_argv = require("containers.util.run_argv")

local M = {}

--- Pull an image from a remote registry
--- @param name string: Name of the image to pull
--- @return boolean, string|nil: success true/false, error message if any
function M.pull_image(name)
  local ok, output = run_argv.run_blocking_captured({ "docker", "pull", name })

  if not ok then
    return false, output
  end

  return true
end

return M
