local M = {}

--- Remove a specific container
--- @param container_id string: ID or name of the container to remove
--- @return nil
function M.remove_container(container_id)
  local cmd = { "podman", "rm", container_id }

  vim.fn.jobstart(cmd, {
    on_exit = function(_, code, _)
      vim.schedule(function()
        if code == 0 then
          vim.notify("Container removed: " .. container_id, vim.log.levels.INFO)
        else
          vim.notify("Failed to remove container: " .. container_id, vim.log.levels.ERROR)
        end
      end)
    end,
  })
end

return M
