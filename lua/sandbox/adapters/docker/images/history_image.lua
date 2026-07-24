-- Docker Adapter: Function to show an image's layer history

local run_argv = require("sandbox.util.run_argv")

local M = {}

--- Show an image's layer history
--- @param image string: image ID or repository:tag
--- @return string[]|nil lines, string|nil err
function M.history_image(image)
  local ok, output = run_argv.run_blocking_captured({ "docker", "history", image })

  if not ok then
    return nil, output
  end

  return vim.split(output, "\n", { plain = true }), nil
end

return M
