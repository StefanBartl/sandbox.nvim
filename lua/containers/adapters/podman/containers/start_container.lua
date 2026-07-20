local run_argv = require("containers.util.run_argv")
local notify = require("containers.notify")

local M = {}

--- Start a specific container
--- @param container_id string: ID or name of the container to start
--- @return boolean: true if successful, false if an error occurred
function M.start_container(container_id)
  local ok, output = run_argv.run_blocking_captured({ "podman", "start", container_id })

  if not ok then
    notify.error("Podman start error: " .. output)
    return false
  end

  return true
end

return M
