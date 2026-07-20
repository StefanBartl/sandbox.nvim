-- Docker Adapter: Function to prune dangling images

local M = {}

--- Prune all dangling images
--- @param on_done? fun(ok: boolean, err: string|nil)
function M.prune_images(on_done)
  local stderr_lines = {}

  vim.fn.jobstart({ "docker", "image", "prune", "-f" }, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stderr = function(_, data)
      if data then
        vim.list_extend(stderr_lines, data)
      end
    end,
    on_exit = function(_, code)
      vim.schedule(function()
        if on_done then
          if code == 0 then
            on_done(true, nil)
          else
            local err = table.concat(stderr_lines, "\n")
            on_done(false, err ~= "" and err or ("exit code " .. code))
          end
        end
      end)
    end,
  })
end

return M
