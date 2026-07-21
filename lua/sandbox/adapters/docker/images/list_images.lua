-- Docker Adapter: Function to list all images

local run_argv = require("sandbox.util.run_argv")

local M = {}

--- List all local images
--- @return table[]|nil images, string|nil err
function M.list_images()
  local ok, output = run_argv.run_blocking_captured({ "docker", "images", "--format", "{{json .}}" })

  if not ok then
    return nil, output
  end

  local images = {}
  local decode_errors = {}
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
      table.insert(decode_errors, tostring(line))
    end
  end

  if #decode_errors > 0 then
    return images, "JSON decode error(s):\n" .. table.concat(decode_errors, "\n")
  end

  return images, nil
end

return M
