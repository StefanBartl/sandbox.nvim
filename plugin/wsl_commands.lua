---@module 'plugin.wsl_commands'
---@brief Neovim user commands for WSL distro management.
---@description
--- These commands are only registered when WSL is detected as available on the system.
--- They operate independently of the container engine (Docker/Podman).

local engine_utils = require("containers.engine_utils")

-- Guard: only register WSL commands on systems where wsl.exe is accessible.
-- On Linux/macOS this will be false unless running inside WSL with wsl.exe in PATH.
if not engine_utils.is_executable("wsl") then
  return
end

local wsl_engine = require("containers.adapters.wsl.engine")

--- List all registered WSL distributions
vim.api.nvim_create_user_command("WslList", function()
  local usecase = require("containers.core.usecases.wsl.list_distros")

  local ok, distros = pcall(usecase, wsl_engine)
  if not ok or type(distros) ~= "table" then
    vim.notify("[nvim-containers] Failed to list WSL distros", vim.log.levels.ERROR)
    return
  end

  -- Reuse the existing list_view pattern with a compatible shape
  vim.cmd("vnew")
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_name(buf, "nvim-containers://wsl-list")

  local lines = { "NAME                    STATE       DEFAULT" }
  lines[#lines + 1] = string.rep("-", 50)

  for _, d in ipairs(distros) do
    lines[#lines + 1] = string.format(
      "%-23s %-11s %s",
      d.name,
      d.state,
      d.default and "*" or ""
    )
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].buftype    = "nofile"
  vim.bo[buf].bufhidden  = "wipe"
  vim.bo[buf].filetype   = "log"
end, {})

--- Start a WSL distro
--- Usage: :WslStart <distro-name>
vim.api.nvim_create_user_command("WslStart", function(opts)
  local name = opts.args
  if not name or name == "" then
    vim.notify("Usage: :WslStart <distro-name>", vim.log.levels.WARN)
    return
  end

  local usecase = require("containers.core.usecases.wsl.start_distro")
  local ok, err = pcall(usecase, wsl_engine, name)
  if not ok then
    vim.notify("[nvim-containers] WSL start failed: " .. err, vim.log.levels.ERROR)
    return
  end

  vim.notify("[nvim-containers] WSL distro started: " .. name, vim.log.levels.INFO)
end, { nargs = 1 })

--- Stop (terminate) a WSL distro
--- Usage: :WslStop <distro-name>
vim.api.nvim_create_user_command("WslStop", function(opts)
  local name = opts.args
  if not name or name == "" then
    vim.notify("Usage: :WslStop <distro-name>", vim.log.levels.WARN)
    return
  end

  local usecase = require("containers.core.usecases.wsl.stop_distro")
  local ok, err = pcall(usecase, wsl_engine, name)
  if not ok then
    vim.notify("[nvim-containers] WSL stop failed: " .. err, vim.log.levels.ERROR)
    return
  end

  vim.notify("[nvim-containers] WSL distro terminated: " .. name, vim.log.levels.INFO)
end, { nargs = 1 })

--- Open a shell or run a command inside a WSL distro
--- Usage: :WslExec <distro-name> [<command> ...]
vim.api.nvim_create_user_command("WslExec", function(opts)
  local name = opts.fargs[1]
  if not name or name == "" then
    vim.notify("Usage: :WslExec <distro-name> [<command>...]", vim.log.levels.WARN)
    return
  end

  local command = {}
  for i = 2, #opts.fargs do
    command[#command + 1] = opts.fargs[i]
  end
  if #command == 0 then
    command = nil
  end

  local usecase = require("containers.core.usecases.wsl.exec_in_distro")
  local ok, err = pcall(usecase, wsl_engine, name, command)
  if not ok then
    vim.notify("[nvim-containers] WSL exec failed: " .. err, vim.log.levels.ERROR)
  end
end, { nargs = "+", complete = "file" })
