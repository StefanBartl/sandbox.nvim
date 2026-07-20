local notify = require("containers.notify")
local M = {}

function M.prune_containers()
  local cmd = { "podman", "container", "prune", "-f" }

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
