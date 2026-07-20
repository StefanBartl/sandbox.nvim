-- Podman Adapter: List images

local run_argv = require("containers.util.run_argv")

local M = {}

--- List all local podman images
--- @return table[]|nil images, string|nil err
function M.list_images()
  local ok, output = run_argv.run_blocking_captured({ "podman", "images", "--format", "json" })

  if not ok then
    return nil, output
  end

  local decode_ok, result = pcall(vim.fn.json_decode, output)
  if not decode_ok then
    return nil, "invalid image JSON output"
  end

  return result, nil
end

return M
