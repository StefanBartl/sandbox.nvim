-- Podman Adapter: Remove image

local notify = require("containers.notify")
local M = {}

--- Remove an image by ID or name
--- @param id string
function M.remove_image(id)
  vim.fn.jobstart({ "podman", "rmi", id }, {
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
          notify.info("Image removed: " .. id)
        else
          notify.error("Failed to remove image: " .. id)
        end
      end)
    end,
  })
end

return M
