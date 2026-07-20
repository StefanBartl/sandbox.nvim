local M = {}

--- Remove a specific container
--- @param container_id string: ID or name of the container to remove
--- @param on_done? fun(ok: boolean, err: string|nil)
function M.remove_container(container_id, on_done)
  local cmd = { "podman", "rm", container_id }

  vim.fn.jobstart(cmd, {
    on_exit = function(_, code, _)
      vim.schedule(function()
        if on_done then
          if code == 0 then
            on_done(true, nil)
          else
            on_done(false, "Failed to remove container: " .. container_id)
          end
        end
      end)
    end,
  })
end

return M
