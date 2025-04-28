-- Docker Adapter: Function to remove a local image

local M = {}

--- Remove a specific image by ID or repository:tag
--- @param id string: Image ID or name
function M.remove_image(id)
  vim.fn.jobstart({ "docker", "rmi", id }, {
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
          vim.notify("[nvim-containers] Image removed: " .. id, vim.log.levels.INFO)
        else
          vim.notify("[nvim-containers] Failed to remove image: " .. id, vim.log.levels.ERROR)
        end
      end)
    end,
  })
end

return M
