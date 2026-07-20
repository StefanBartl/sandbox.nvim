-- Docker Adapter: Function to remove a container

local notify = require("containers.notify")
local M = {}

--- Remove a specific container
--- @param container_id string: ID or name of the container to remove
function M.remove_container(container_id)
  local cmd = { "docker", "rm", container_id }

  vim.fn.jobstart(cmd, {
    on_exit = function(_, code, _)
      vim.schedule(function()
        if code == 0 then
          notify.info("Container removed: " .. container_id)
        else
          notify.error("Failed to remove container: " .. container_id)
        end
      end)
    end,
  })
end

return M
