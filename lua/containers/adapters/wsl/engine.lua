---@module 'containers.adapters.wsl.engine'
---@brief Aggregates all WSL adapter functions into a single WslEngine implementation.

local list_distros   = require("containers.adapters.wsl.list_distros")
local start_distro   = require("containers.adapters.wsl.start_distro")
local stop_distro    = require("containers.adapters.wsl.stop_distro")
local exec_in_distro = require("containers.adapters.wsl.exec_in_distro")

return {
  list_distros   = list_distros.list_distros,
  start_distro   = start_distro.start_distro,
  stop_distro    = stop_distro.stop_distro,
  exec_in_distro = exec_in_distro.exec_in_distro,
}
