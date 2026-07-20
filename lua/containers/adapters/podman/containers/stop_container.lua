local notify = require("containers.notify")
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
          notify.error("Error stopping container: exit code " .. code)
        end
      end)
    end,
  })
end

return M
