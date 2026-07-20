-- Docker Adapter: Function to kill a container

local M = {}

--- Kill a specific container
--- @param container_id string: ID or name of the container to kill
--- @param on_done? fun(ok: boolean, err: string|nil)
function M.kill_container(container_id, on_done)
  local cmd = { "docker", "kill", container_id }

  vim.fn.jobstart(cmd, {
    on_exit = function(_, code, _)
      vim.schedule(function()
        if on_done then
          if code == 0 then
            on_done(true, nil)
          else
            on_done(false, "Error killing container: exit code " .. code)
          end
        end
      end)
    end,
  })
end

return M
