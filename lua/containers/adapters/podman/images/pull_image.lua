-- Podman Adapter: Pull image

local M = {}

--- Pull an image by name
--- @param name string
--- @return boolean, string|nil
function M.pull_image(name)
  local output = vim.fn.system({ "podman", "pull", name })

  if vim.v.shell_error ~= 0 then
    return false, output
  end

  return true
end

return M
