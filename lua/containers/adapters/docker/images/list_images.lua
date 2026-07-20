-- Docker Adapter: Function to list all images

local run_argv = require("containers.util.run_argv")
local notify = require("containers.notify")

local M = {}

--- List all local images
--- @return table[]: List of images, or error table
function M.list_images()
  local ok, output = run_argv.run_blocking_captured({ "docker", "images", "--format", "{{json .}}" })

  if not ok then
    return { "[nvim-containers] Failed to list images: " .. output }
  end

  local images = {}
  for _, line in ipairs(vim.split(output, "\n", { trimempty = true })) do
    local decode_ok, image = pcall(vim.fn.json_decode, line)
    if decode_ok and image then
      table.insert(images, {
        id = image.ID or "<no id>",
        repository = image.Repository or "<no repository>",
        tag = image.Tag or "<no tag>",
        size = image.Size or "<no size>",
      })
    else
      notify.error("JSON decode error: " .. tostring(line))
    end
  end

  return images
end

return M
