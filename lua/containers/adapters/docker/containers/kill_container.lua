-- Docker Adapter: Function to kill a container

local M = {}

--- Kill a specific container
--- @param container_id string: ID or name of the container to kill
function M.kill_container(container_id)
  local cmd = { "docker", "kill", container_id }

  vim.fn.jobstart(cmd, {
    on_exit = function(_, code, _)
      vim.schedule(function()
        if code == 0 then
          vim.notify("[nvim-containers] Container killed: " .. container_id, vim.log.levels.INFO)
        else
          vim.notify("[nvim-containers] Error killing container: exit code " .. code, vim.log.levels.ERROR)
        end
      end)
    end,
  })
end

return M
