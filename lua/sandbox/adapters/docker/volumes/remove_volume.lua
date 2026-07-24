-- Docker Adapter: Function to remove a volume

local M = {}

--- Remove a specific volume by name
--- @param name string
--- @param on_done? fun(ok: boolean, err: string|nil)
function M.remove_volume(name, on_done)
  local cmd = { "docker", "volume", "rm", name }

  vim.fn.jobstart(cmd, {
    on_exit = function(_, code, _)
      vim.schedule(function()
        if on_done then
          if code == 0 then
            on_done(true, nil)
          else
            on_done(false, "exit code " .. code)
          end
        end
      end)
    end,
  })
end

return M
