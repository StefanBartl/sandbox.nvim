-- Docker Adapter: Function to start a container

local run_argv = require("containers.util.run_argv")

local M = {}

--- Start a specific container
--- @param container_id string: ID or name of the container to start
--- @return boolean: True if the container was started successfully, false otherwise
function M.start_container(container_id)
  local ok, output = run_argv.run_blocking_captured({ "docker", "start", container_id })

  if not ok then
    vim.notify("[nvim-containers] Docker start error: " .. output, vim.log.levels.ERROR)
    return false
  end

  return true
end

return M
