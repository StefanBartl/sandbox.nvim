-- Docker Adapter: Function to stop a container

local M = {}

--- Stop a specific container
--- @param container_id string: ID or name of the container to stop
function M.stop_container(container_id)
  local cmd = { "docker", "stop", "--time=1", container_id }

  vim.fn.jobstart(cmd, {
    on_exit = function(_, code, _)
      vim.schedule(function()
        if code ~= 0 then
          vim.notify("[nvim-containers] Error stopping container: exit code " .. code, vim.log.levels.ERROR)
        end
      end)
    end,
  })
end

return M
