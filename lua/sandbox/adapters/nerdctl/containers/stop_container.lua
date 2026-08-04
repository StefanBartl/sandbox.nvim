---@module 'sandbox.adapters.nerdctl.containers.stop_container'
--- Nerdctl Adapter: Function to stop a container

local M = {}

--- Stop a specific container
--- @param container_id string: ID or name of the container to stop
--- @param on_done? fun(ok: boolean, err: string|nil)
function M.stop_container(container_id, on_done)
  local cmd = { "nerdctl", "stop", "--time=1", container_id }

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
