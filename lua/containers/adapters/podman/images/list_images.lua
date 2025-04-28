-- Podman Adapter: List images

local M = {}

--- List all local podman images
--- @return table[]: List of images, or error message if failed
function M.list_images()
  local output = vim.fn.system({ "podman", "images", "--format", "json" })

  if vim.v.shell_error ~= 0 then
    return { "[nvim-containers] Failed to list images: " .. output }
  end

  local ok, result = pcall(vim.fn.json_decode, output)
  if not ok then
    return { "[nvim-containers] Invalid image JSON output" }
  end

  return result
end

return M
