-- Podman Adapter: Bring a compose project up (detached)

local M = {}

--- @param file string path to the compose file
--- @param on_done? fun(ok: boolean, err: string|nil)
function M.up(file, on_done)
  local cmd = { "podman", "compose", "-f", file, "up", "-d" }
  local stderr_lines = {}

  vim.fn.jobstart(cmd, {
    stderr_buffered = true,
    on_stderr = function(_, data)
      if data then
        vim.list_extend(stderr_lines, data)
      end
    end,
    on_exit = function(_, code)
      vim.schedule(function()
        if not on_done then
          return
        end
        if code == 0 then
          on_done(true, nil)
        else
          local err = table.concat(stderr_lines, "\n")
          on_done(false, err ~= "" and err or ("exit code " .. code))
        end
      end)
    end,
  })
end

return M
