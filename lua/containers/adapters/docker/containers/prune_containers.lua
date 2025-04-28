-- Docker Adapter: Function to prune all stopped containers

local M = {}

--- Remove all stopped containers
function M.prune_containers()
  local cmd = { "docker", "container", "prune", "-f" }

  vim.fn.jobstart(cmd, {
    on_exit = function(_, code, _)
      vim.schedule(function()
        if code == 0 then
          vim.notify("[nvim-containers] Pruned all stopped containers", vim.log.levels.INFO)
        else
          vim.notify("[nvim-containers] Failed to prune containers", vim.log.levels.ERROR)
        end
      end)
    end,
  })
end

return M
