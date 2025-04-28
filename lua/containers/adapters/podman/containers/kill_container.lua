local M = {}

--- Kill a specific container
--- @param container_id string: ID or name of the container to kill
--- @return nil
function M.kill_container(container_id)
  local cmd = { "podman", "kill", container_id }

  vim.fn.jobstart(cmd, {
    on_exit = function(_, code, _)
      vim.schedule(function()
        if code == 0 then
          vim.notify("Container killed: " .. container_id, vim.log.levels.INFO)
        else
          vim.notify("Error killing container (code " .. code .. "): " .. container_id, vim.log.levels.ERROR)
        end
      end)
    end,
  })
end

return M
