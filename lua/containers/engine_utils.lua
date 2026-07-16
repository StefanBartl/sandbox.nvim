-- Utility to detect available container engine

local notify = require("containers.notify")

local M = {}

--- Check if a command is available on the system.
--- Delegates to lib.nvim.core.has_exec, which memoizes the result per binary
--- name (this module's own version re-checked vim.fn.executable every call).
--- @param cmd string
--- @return boolean
function M.is_executable(cmd)
  return require("lib.nvim.core").has_exec(cmd)
end

--- Detect which container engine is available
--- @return Containers.Engine
function M.get_engine()
  if M.is_executable("podman") then
    return "podman"
  elseif M.is_executable("docker") then
    return "docker"
  else
    notify.error("No supported container engine (podman/docker) found in PATH.")
    return "docker" -- fallback to docker to avoid crash, user will see error
  end
end

return M
