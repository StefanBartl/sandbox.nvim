-- Docker Adapter: Function to list all images

local M = {}

--- List all local images
--- @return table[]: List of images, or error table
function M.list_images()
  local output = vim.fn.system({ "docker", "images", "--format", "{{json .}}" })

  if vim.v.shell_error ~= 0 then
    return { "[nvim-containers] Failed to list images: " .. output }
  end

  local images = {}
  for _, line in ipairs(vim.split(output, "\n", { trimempty = true })) do
    local ok, image = pcall(vim.fn.json_decode, line)
    if ok and image then
      table.insert(images, {
        id = image.ID or "<no id>",
        repository = image.Repository or "<no repository>",
        tag = image.Tag or "<no tag>",
        size = image.Size or "<no size>",
      })
    else
      vim.notify("[nvim-containers] JSON decode error: " .. tostring(line), vim.log.levels.ERROR)
    end
  end

  return images
end

return M
