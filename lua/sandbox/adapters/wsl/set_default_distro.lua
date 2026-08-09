---@module 'sandbox.adapters.wsl.set_default_distro'
---@brief Sets a WSL distro as the default (`wsl --set-default <name>`).

local run_argv = require("sandbox.util.run_argv")

local M = {}

---@param name string
---@return boolean ok
---@return string|nil err
function M.set_default_distro(name)
  local ok, output = run_argv.run_blocking_captured({ "wsl", "--set-default", name })

  if not ok then
    return false, output
  end

  return true, nil
end

return M
