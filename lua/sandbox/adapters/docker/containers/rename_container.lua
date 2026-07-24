-- Docker Adapter: Function to rename a container

local run_argv = require("sandbox.util.run_argv")

local M = {}

--- Rename a specific container
--- @param container_id string: ID or name of the container to rename
--- @param new_name string: new name for the container
--- @return boolean ok, string|nil err
function M.rename_container(container_id, new_name)
  local ok, output = run_argv.run_blocking_captured({ "docker", "rename", container_id, new_name })

  if not ok then
    return false, output
  end

  return true, nil
end

return M
