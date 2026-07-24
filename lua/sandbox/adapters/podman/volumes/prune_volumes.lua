-- Podman Adapter: Function to prune unused volumes

local M = {}

--- Remove all unused local volumes
--- @param on_done? fun(ok: boolean, err: string|nil)
function M.prune_volumes(on_done)
  local cmd = { "podman", "volume", "prune", "-f" }

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
