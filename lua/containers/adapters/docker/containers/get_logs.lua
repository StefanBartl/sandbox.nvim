-- Docker Adapter: Function to retrieve logs of a container

local run_argv = require("containers.util.run_argv")

local M = {}

--- Retrieve the logs of a specific container
--- @param container_id string: ID or name of the container to retrieve logs from
--- @return string[]|nil lines, string|nil err
function M.get_logs(container_id)
  local ok, output = run_argv.run_blocking_captured({ "docker", "logs", container_id })

  if not ok then
    return nil, "Docker logs error: " .. output
  end

  return vim.split(output, "\n", { plain = true }), nil
end

return M
