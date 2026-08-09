---@module 'sandbox.bindings.usrcmds.wsl_commands'
---@brief WSL distro management handlers.
---@description
--- These operate independently of the container engine (Docker/Podman) and
--- are only wired up as the "wsl" sub-namespace of the :Sandbox/:Sbx
--- composer verb when wsl.exe is actually reachable (M.available(), checked
--- by bindings/usrcmds/init.lua before building the route table) -- this
--- file no longer registers commands itself, so on Linux/macOS the wsl
--- routes are simply omitted rather than registered as commands that would
--- always fail).
---
--- Exported as plain functions rather than registering commands directly, so
--- lib.nvim.usercmd.composer can build typed routes + <Tab> completion
--- around them. Each function's own body is unchanged from before the
--- composer migration; only the registration site moved.

local engine_utils = require("sandbox.engine_utils")
local notify = require("sandbox.notify")
local friendly_error = require("sandbox.util.friendly_error")
local confirm = require("sandbox.util.confirm")

local M = {}

---@return boolean
function M.available()
  return engine_utils.is_executable("wsl")
end

--- List all registered WSL distributions
function M.list()
  local wsl_engine = require("sandbox.adapters.wsl.engine")
  local usecase = require("sandbox.core.usecases.wsl.list_distros")

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
    lines[#lines + 1] = string.format("%-23s %-11s %s", d.name, d.state, d.default and "*" or "")
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "log"
end

--- Start a WSL distro
---@param name string
function M.start(name)
  if not name or name == "" then
    notify.warn("Usage: :Sandbox wsl start <distro-name>")
    return
  end

  local wsl_engine = require("sandbox.adapters.wsl.engine")
  local usecase = require("sandbox.core.usecases.wsl.start_distro")
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
    notify.warn("Usage: :Sandbox wsl stop <distro-name>")
    return
  end

  local wsl_engine = require("sandbox.adapters.wsl.engine")
  local usecase = require("sandbox.core.usecases.wsl.stop_distro")
  local ok, err = usecase(wsl_engine, name)
  if not ok then
    notify.error("Failed to stop WSL distro " .. name .. ": " .. friendly_error(err), { name = name, err = err })
    return
  end

  notify.info("WSL distro terminated: " .. name)
end

--- Set a distro as the WSL default (`wsl --set-default`)
---@param name string
function M.set_default(name)
  if not name or name == "" then
    notify.warn("Usage: :Sandbox wsl set-default <distro-name>")
    return
  end

  local wsl_engine = require("sandbox.adapters.wsl.engine")
  local usecase = require("sandbox.core.usecases.wsl.set_default_distro")
  local ok, err = usecase(wsl_engine, name)
  if not ok then
    notify.error("Failed to set default WSL distro " .. name .. ": " .. friendly_error(err), { name = name, err = err })
    return
  end

  notify.info("Default WSL distro set to: " .. name)
end

--- Toggle a distro between WSL1/WSL2 (`wsl --set-version`)
---@param name string
---@param version string "1" or "2"
function M.set_version(name, version)
  if not name or name == "" or (version ~= "1" and version ~= "2") then
    notify.warn("Usage: :Sandbox wsl set-version <distro-name> <1|2>")
    return
  end

  local version_num = version == "1" and 1 or 2

  local wsl_engine = require("sandbox.adapters.wsl.engine")
  local usecase = require("sandbox.core.usecases.wsl.set_version_distro")
  local ok, err = usecase(wsl_engine, name, version_num)
  if not ok then
    notify.error("Failed to set WSL version for " .. name .. ": " .. friendly_error(err), { name = name, err = err })
    return
  end

  notify.info("WSL distro " .. name .. " set to version " .. version)
end

--- Open a shell or run a command inside a WSL distro
---@param name string
---@param command string[]|nil
function M.exec(name, command)
  if not name or name == "" then
    notify.warn("Usage: :Sandbox wsl exec <distro-name> [<command>...]")
    return
  end

  if command and #command == 0 then
    command = nil
  end

  local wsl_engine = require("sandbox.adapters.wsl.engine")
  local usecase = require("sandbox.core.usecases.wsl.exec_in_distro")
  local ok, err = pcall(usecase, wsl_engine, name, command)
  if not ok then
    notify.error("Failed to exec in WSL distro " .. name .. ": " .. tostring(err), { name = name, err = err })
  end
end

--- Export a distro to a tarball on disk (`wsl --export`)
---@param name string
---@param path string destination .tar file path
function M.export(name, path)
  if not name or name == "" or not path or path == "" then
    notify.warn("Usage: :Sandbox wsl export <distro-name> <path>")
    return
  end

  local wsl_engine = require("sandbox.adapters.wsl.engine")
  local usecase = require("sandbox.core.usecases.wsl.export_distro")
  local ok, err = usecase(wsl_engine, name, path)
  if not ok then
    notify.error("Failed to export WSL distro " .. name .. ": " .. friendly_error(err), { name = name, err = err })
    return
  end

  notify.info("WSL distro " .. name .. " exported to " .. path)
end

--- Import a distro from a tarball (`wsl --import`)
---@param name string new distro name
---@param install_path string directory the distro's VHD will be installed into
---@param tar_path string source .tar file path
function M.import(name, install_path, tar_path)
  if not name or name == "" or not install_path or install_path == "" or not tar_path or tar_path == "" then
    notify.warn("Usage: :Sandbox wsl import <distro-name> <install-path> <tar-path>")
    return
  end

  local wsl_engine = require("sandbox.adapters.wsl.engine")
  local usecase = require("sandbox.core.usecases.wsl.import_distro")
  local ok, err = usecase(wsl_engine, name, install_path, tar_path)
  if not ok then
    notify.error("Failed to import WSL distro " .. name .. ": " .. friendly_error(err), { name = name, err = err })
    return
  end

  notify.info("WSL distro imported: " .. name)
end

--- Shut down the WSL2 VM and all running distros (`wsl --shutdown`),
--- distinct from stopping a single named distro.
function M.shutdown_all()
  confirm.destructive("Shut down WSL and all running distros?", function()
    local wsl_engine = require("sandbox.adapters.wsl.engine")
    local usecase = require("sandbox.core.usecases.wsl.shutdown_all")
    local ok, err = usecase(wsl_engine)
    if not ok then
      notify.error("Failed to shut down WSL: " .. friendly_error(err), { err = err })
      return
    end

    notify.info("WSL shut down")
  end)
end

return M
