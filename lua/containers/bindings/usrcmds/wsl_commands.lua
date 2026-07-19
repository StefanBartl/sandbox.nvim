---@module 'containers.bindings.usrcmds.wsl_commands'
---@brief WSL distro management handlers.
---@description
--- These operate independently of the container engine (Docker/Podman) and
--- are only wired up as a :Wsl composer verb when wsl.exe is actually
--- reachable (M.available(), checked by bindings/usrcmds/init.lua before
--- calling composer.verb("Wsl", ...) -- this file no longer registers
--- commands itself, so on Linux/macOS it's simply never wired up rather than
--- registering commands that would always fail).
---
--- Exported as plain functions rather than registering commands directly, so
--- lib.nvim.usercmd.composer can build typed routes + <Tab> completion
--- around them. Each function's own body is unchanged from before the
--- composer migration; only the registration site moved.

local engine_utils = require("containers.engine_utils")

local M = {}

---@return boolean
function M.available()
  return engine_utils.is_executable("wsl")
end

--- List all registered WSL distributions
function M.list()
  local wsl_engine = require("containers.adapters.wsl.engine")
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
end

--- Start a WSL distro
---@param name string
function M.start(name)
  if not name or name == "" then
    vim.notify("Usage: :Wsl start <distro-name>", vim.log.levels.WARN)
    return
  end

  local wsl_engine = require("containers.adapters.wsl.engine")
  local usecase = require("containers.core.usecases.wsl.start_distro")
  local ok, err = pcall(usecase, wsl_engine, name)
  if not ok then
    vim.notify("[nvim-containers] WSL start failed: " .. err, vim.log.levels.ERROR)
    return
  end

  vim.notify("[nvim-containers] WSL distro started: " .. name, vim.log.levels.INFO)
end

--- Stop (terminate) a WSL distro
---@param name string
function M.stop(name)
  if not name or name == "" then
    vim.notify("Usage: :Wsl stop <distro-name>", vim.log.levels.WARN)
    return
  end

  local wsl_engine = require("containers.adapters.wsl.engine")
  local usecase = require("containers.core.usecases.wsl.stop_distro")
  local ok, err = pcall(usecase, wsl_engine, name)
  if not ok then
    vim.notify("[nvim-containers] WSL stop failed: " .. err, vim.log.levels.ERROR)
    return
  end

  vim.notify("[nvim-containers] WSL distro terminated: " .. name, vim.log.levels.INFO)
end

--- Open a shell or run a command inside a WSL distro
---@param name string
---@param command string[]|nil
function M.exec(name, command)
  if not name or name == "" then
    vim.notify("Usage: :Wsl exec <distro-name> [<command>...]", vim.log.levels.WARN)
    return
  end

  if command and #command == 0 then
    command = nil
  end

  local wsl_engine = require("containers.adapters.wsl.engine")
  local usecase = require("containers.core.usecases.wsl.exec_in_distro")
  local ok, err = pcall(usecase, wsl_engine, name, command)
  if not ok then
    vim.notify("[nvim-containers] WSL exec failed: " .. err, vim.log.levels.ERROR)
  end
end

return M
