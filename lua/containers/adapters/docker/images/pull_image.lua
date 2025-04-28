-- Docker Adapter: Function to pull an image

local M = {}

--- Pull an image from a remote registry
--- @param name string: Name of the image to pull
--- @return boolean, string|nil: success true/false, error message if any
function M.pull_image(name)
  local output = vim.fn.system({ "docker", "pull", name })

  if vim.v.shell_error ~= 0 then
    return false, output
  end

  return true
end

return M
