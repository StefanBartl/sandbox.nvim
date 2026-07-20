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
local notify = require("containers.notify")
local friendly_error = require("containers.util.friendly_error")

local M = {}

---@return boolean
function M.available()
  return engine_utils.is_executable("wsl")
end

--- List all registered WSL distributions
function M.list()
  local wsl_engine = require("containers.adapters.wsl.engine")
  local usecase = require("containers.core.usecases.wsl.list_distros")

  local distros, err = usecase(wsl_engine)
  if not distros then
    notify.error("Failed to list WSL distros: " .. friendly_error(err), { err = err })
    return
  end

  -- Reuse the existing list_view pattern with a compatible shape
  vim.cmd("vnew")
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_name(buf, "sandbox.nvim://wsl-list")

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
    notify.warn("Usage: :Wsl start <distro-name>")
    return
  end

  local wsl_engine = require("containers.adapters.wsl.engine")
  local usecase = require("containers.core.usecases.wsl.start_distro")
  local ok, err = usecase(wsl_engine, name)
  if not ok then
    notify.error("Failed to start WSL distro " .. name .. ": " .. friendly_error(err), { name = name, err = err })
    return
  end

  notify.info("WSL distro started: " .. name)
end

--- Stop (terminate) a WSL distro
---@param name string
function M.stop(name)
  if not name or name == "" then
    notify.warn("Usage: :Wsl stop <distro-name>")
    return
  end

  local wsl_engine = require("containers.adapters.wsl.engine")
  local usecase = require("containers.core.usecases.wsl.stop_distro")
  local ok, err = usecase(wsl_engine, name)
  if not ok then
    notify.error("Failed to stop WSL distro " .. name .. ": " .. friendly_error(err), { name = name, err = err })
    return
  end

  notify.info("WSL distro terminated: " .. name)
end

--- Open a shell or run a command inside a WSL distro
---@param name string
---@param command string[]|nil
function M.exec(name, command)
  if not name or name == "" then
    notify.warn("Usage: :Wsl exec <distro-name> [<command>...]")
    return
  end

  if command and #command == 0 then
    command = nil
  end

  local wsl_engine = require("containers.adapters.wsl.engine")
  local usecase = require("containers.core.usecases.wsl.exec_in_distro")
  local ok, err = pcall(usecase, wsl_engine, name, command)
  if not ok then
    notify.error("Failed to exec in WSL distro " .. name .. ": " .. tostring(err), { name = name, err = err })
  end
end

return M
