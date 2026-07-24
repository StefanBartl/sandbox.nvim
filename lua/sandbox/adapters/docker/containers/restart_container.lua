-- Docker Adapter: Function to restart a container

local M = {}

--- Restart a specific container
--- @param container_id string: ID or name of the container to restart
--- @param on_done? fun(ok: boolean, err: string|nil)
function M.restart_container(container_id, on_done)
  local cmd = { "docker", "restart", container_id }

  vim.fn.jobstart(cmd, {
    on_exit = function(_, code, _)
      vim.schedule(function()
        if on_done then
          if code == 0 then
            on_done(true, nil)
          else
            on_done(false, "exit code " .. code)
          end
        end
      end)
    end,
  })
end

return M
