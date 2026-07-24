-- Docker Adapter: Function to tag a local image

local run_argv = require("sandbox.util.run_argv")

local M = {}

--- Tag a local image with a new repository:tag
--- @param source string: existing image ID or repository:tag
--- @param target string: new repository:tag
--- @return boolean ok, string|nil err
function M.tag_image(source, target)
  local ok, output = run_argv.run_blocking_captured({ "docker", "tag", source, target })

  if not ok then
    return false, output
  end

  return true, nil
end

return M
