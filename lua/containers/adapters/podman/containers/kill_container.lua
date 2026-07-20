local notify = require("containers.notify")
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
          notify.info("Container killed: " .. container_id)
        else
          notify.error("Error killing container (code " .. code .. "): " .. container_id)
        end
      end)
    end,
  })
end

return M
