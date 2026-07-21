-- Podman Adapter: Pull image

local run_argv = require("sandbox.util.run_argv")

local M = {}

--- Pull an image by name
--- @param name string
--- @return boolean, string|nil
function M.pull_image(name)
  local ok, output = run_argv.run_blocking_captured({ "podman", "pull", name })

  if not ok then
    return false, output
  end

  return true
end

return M
