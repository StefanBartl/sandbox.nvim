-- Docker Adapter: Function to prune dangling images

local M = {}

--- Prune all dangling images
function M.prune_images()
  vim.fn.jobstart({ "docker", "image", "prune", "-f" }, {
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
          vim.notify("[nvim-containers] Image prune completed", vim.log.levels.INFO)
        else
          vim.notify("[nvim-containers] Image prune failed", vim.log.levels.ERROR)
        end
      end)
    end,
  })
end

return M
