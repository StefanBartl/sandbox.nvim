-- Docker Adapter: Function to import an image from a tarball

local run_argv = require("sandbox.util.run_argv")

local M = {}

--- Load (import) an image from a tarball on disk
--- @param path string: tarball path
--- @return boolean ok, string|nil err
function M.load_image(path)
  local ok, output = run_argv.run_blocking_captured({ "docker", "load", "-i", path })

  if not ok then
    return false, output
  end

  return true, nil
end

return M
