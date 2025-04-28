-- Podman Adapter: Prune images

local M = {}

--- Remove all dangling podman images
function M.prune_images()
  vim.fn.jobstart({ "podman", "image", "prune", "-f" }, {
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
          vim.notify("Image prune completed", vim.log.levels.INFO)
        else
          vim.notify("Image prune failed", vim.log.levels.ERROR)
        end
      end)
    end,
  })
end

return M
