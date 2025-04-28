local M = {}

--- Stop a specific container
--- @param container_id string: ID or name of the container to stop
--- @return nil
function M.stop_container(container_id)
  local cmd = { "podman", "stop", "--timeout", "1", container_id }

  vim.fn.jobstart(cmd, {
    on_exit = function(_, code, _)
      vim.schedule(function()
        if code ~= 0 then
          vim.notify("Error stopping container: exit code " .. code, vim.log.levels.ERROR)
        end
      end)
    end,
  })
end

return M
