-- Docker Adapter: Function to list processes running inside a container

local run_argv = require("sandbox.util.run_argv")

local M = {}

--- List the processes running inside a specific container
--- @param container_id string: ID or name of the container
--- @return string[]|nil lines, string|nil err
function M.top_container(container_id)
  local ok, output = run_argv.run_blocking_captured({ "docker", "top", container_id })

  if not ok then
    return nil, output
  end

  return vim.split(output, "\n", { plain = true }), nil
end

return M
