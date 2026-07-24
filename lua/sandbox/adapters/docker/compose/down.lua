-- Docker Adapter: Stop and remove a compose project

local M = {}

--- @param file string path to the compose file
--- @param on_done? fun(ok: boolean, err: string|nil)
function M.down(file, on_done)
  local cmd = { "docker", "compose", "-f", file, "down" }

  vim.fn.jobstart(cmd, {
    on_exit = function(_, code)
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
