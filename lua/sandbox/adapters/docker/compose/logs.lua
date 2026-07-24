-- Docker Adapter: Show logs for a compose project

local run_argv = require("sandbox.util.run_argv")

local M = {}

--- @param file string path to the compose file
--- @return string[]|nil lines, string|nil err
function M.logs(file)
  local ok, output = run_argv.run_blocking_captured({ "docker", "compose", "-f", file, "logs" })

  if not ok then
    return nil, output
  end

  return vim.split(output, "\n", { plain = true }), nil
end

return M
