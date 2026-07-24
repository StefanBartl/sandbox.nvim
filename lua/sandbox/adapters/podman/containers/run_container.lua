-- Podman Adapter: Function to create and start a new container

local M = {}

--- Create and start a new container, detached
--- @param opts Sandbox.RunOpts
--- @param on_done? fun(ok: boolean, result: string|nil) result is the new container id on success, raw error output otherwise
function M.run_container(opts, on_done)
  local cmd = { "podman", "run", "-d" }

  if opts.name and opts.name ~= "" then
    vim.list_extend(cmd, { "--name", opts.name })
  end
  for _, p in ipairs(opts.ports or {}) do
    vim.list_extend(cmd, { "-p", p })
  end
  for _, v in ipairs(opts.volumes or {}) do
    vim.list_extend(cmd, { "-v", v })
  end
  for _, e in ipairs(opts.env or {}) do
    vim.list_extend(cmd, { "-e", e })
  end
  cmd[#cmd + 1] = opts.image

  local stdout_lines = {}
  local stderr_lines = {}

  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        vim.list_extend(stdout_lines, data)
      end
    end,
    on_stderr = function(_, data)
      if data then
        vim.list_extend(stderr_lines, data)
      end
    end,
    on_exit = function(_, code, _)
      vim.schedule(function()
        if not on_done then
          return
        end
        if code == 0 then
          local id = table.concat(stdout_lines, ""):gsub("%s+", "")
          on_done(true, id ~= "" and id or nil)
        else
          on_done(false, table.concat(stderr_lines, "\n"))
        end
      end)
    end,
  })
end

return M
