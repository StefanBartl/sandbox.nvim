-- Docker Adapter: Function to start a container

local run_argv = require("sandbox.util.run_argv")

local M = {}

--- Start a specific container
--- @param container_id string: ID or name of the container to start
--- @return boolean ok, string|nil err
function M.start_container(container_id)
  local ok, output = run_argv.run_blocking_captured({ "docker", "start", container_id })

  if not ok then
    return false, output
  end

  return true, nil
end

return M
