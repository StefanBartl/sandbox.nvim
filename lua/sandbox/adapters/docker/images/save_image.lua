-- Docker Adapter: Function to export an image to a tarball

local run_argv = require("sandbox.util.run_argv")

local M = {}

--- Save (export) an image to a tarball on disk
--- @param image string: image ID or repository:tag
--- @param path string: destination tarball path
--- @return boolean ok, string|nil err
function M.save_image(image, path)
  local ok, output = run_argv.run_blocking_captured({ "docker", "save", "-o", path, image })

  if not ok then
    return false, output
  end

  return true, nil
end

return M
