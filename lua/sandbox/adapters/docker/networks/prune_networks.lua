-- Docker Adapter: Function to prune unused networks

local M = {}

--- Remove all unused local networks
--- @param on_done? fun(ok: boolean, err: string|nil)
function M.prune_networks(on_done)
  local cmd = { "docker", "network", "prune", "-f" }

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
