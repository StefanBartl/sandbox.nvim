-- Podman Adapter: Remove image

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
          vim.notify(table.concat(data, "\n"), vim.log.levels.INFO)
        end)
      end
    end,
    on_stderr = function(_, data)
      if data then
        vim.schedule(function()
          vim.notify(table.concat(data, "\n"), vim.log.levels.ERROR)
        end)
      end
    end,
    on_exit = function(_, code)
      vim.schedule(function()
        if code == 0 then
          vim.notify("Image removed: " .. id, vim.log.levels.INFO)
        else
          vim.notify("Failed to remove image: " .. id, vim.log.levels.ERROR)
        end
      end)
    end,
  })
end

return M
