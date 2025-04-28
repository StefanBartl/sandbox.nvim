-- Docker Adapter: Function to start a container

local M = {}

--- Start a specific container
--- @param container_id string: ID or name of the container to start
--- @return boolean: True if the container was started successfully, false otherwise
function M.start_container(container_id)
  local output = vim.fn.system({ "docker", "start", container_id })

  if vim.v.shell_error ~= 0 then
    vim.notify("[nvim-containers] Docker start error: " .. output, vim.log.levels.ERROR)
    return false
  end

  return true
end

return M
