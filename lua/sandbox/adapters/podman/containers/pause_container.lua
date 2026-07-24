-- Podman Adapter: Functions to pause/unpause a container

local M = {}

--- Pause a specific container's processes
--- @param container_id string: ID or name of the container to pause
--- @param on_done? fun(ok: boolean, err: string|nil)
function M.pause_container(container_id, on_done)
  local cmd = { "podman", "pause", container_id }

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

--- Resume a specific container's processes
--- @param container_id string: ID or name of the container to unpause
--- @param on_done? fun(ok: boolean, err: string|nil)
function M.unpause_container(container_id, on_done)
  local cmd = { "podman", "unpause", container_id }

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
