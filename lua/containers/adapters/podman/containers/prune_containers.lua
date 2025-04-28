local M = {}

function M.prune_containers()
  local cmd = { "podman", "container", "prune", "-f" }

  vim.fn.jobstart(cmd, {
    on_exit = function(_, code, _)
      vim.schedule(function()
        if code == 0 then
          vim.notify("Pruned all stopped containers", vim.log.levels.INFO)
        else
          vim.notify("Failed to prune containers", vim.log.levels.ERROR)
        end
      end)
    end,
  })
end

return M
