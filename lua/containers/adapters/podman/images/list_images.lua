-- Podman Adapter: List images

local run_argv = require("containers.util.run_argv")

local M = {}

--- List all local podman images
--- @return table[]: List of images, or error message if failed
function M.list_images()
  local ok, output = run_argv.run_blocking_captured({ "podman", "images", "--format", "json" })

  if not ok then
    return { "[nvim-containers] Failed to list images: " .. output }
  end

  local decode_ok, result = pcall(vim.fn.json_decode, output)
  if not decode_ok then
    return { "[nvim-containers] Invalid image JSON output" }
  end

  return result
end

return M
