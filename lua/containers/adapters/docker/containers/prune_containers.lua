-- Docker Adapter: Function to prune all stopped containers

local notify = require("containers.notify")
local M = {}

--- Remove all stopped containers
function M.prune_containers()
  local cmd = { "docker", "container", "prune", "-f" }

  vim.fn.jobstart(cmd, {
    on_exit = function(_, code, _)
      vim.schedule(function()
        if code == 0 then
          notify.info("Pruned all stopped containers")
        else
          notify.error("Failed to prune containers")
        end
      end)
    end,
  })
end

return M
