-- Docker Adapter: Function to prune all stopped containers

local M = {}

--- Remove all stopped containers
--- @param on_done? fun(ok: boolean, err: string|nil)
function M.prune_containers(on_done)
  local cmd = { "docker", "container", "prune", "-f" }

  vim.fn.jobstart(cmd, {
    on_exit = function(_, code, _)
      vim.schedule(function()
        if on_done then
          if code == 0 then
            on_done(true, nil)
          else
            on_done(false, "Failed to prune containers")
          end
        end
      end)
    end,
  })
end

return M
