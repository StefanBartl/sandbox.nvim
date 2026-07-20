-- Podman Adapter: Prune images

local notify = require("containers.notify")
local M = {}

--- Remove all dangling podman images
function M.prune_images()
  vim.fn.jobstart({ "podman", "image", "prune", "-f" }, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        vim.schedule(function()
          notify.info(table.concat(data, "\n"))
        end)
      end
    end,
    on_stderr = function(_, data)
      if data then
        vim.schedule(function()
          notify.error(table.concat(data, "\n"))
        end)
      end
    end,
    on_exit = function(_, code)
      vim.schedule(function()
        if code == 0 then
          notify.info("Image prune completed")
        else
          notify.error("Image prune failed")
        end
      end)
    end,
  })
end

return M
