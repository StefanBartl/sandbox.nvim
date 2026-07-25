---@module 'sandbox.adapters.wsl.engine'
---@brief Aggregates all WSL adapter functions into a single WslEngine implementation.

local list_distros       = require("sandbox.adapters.wsl.list_distros")
local start_distro       = require("sandbox.adapters.wsl.start_distro")
local stop_distro        = require("sandbox.adapters.wsl.stop_distro")
local exec_in_distro     = require("sandbox.adapters.wsl.exec_in_distro")
local set_default_distro = require("sandbox.adapters.wsl.set_default_distro")
local set_version_distro = require("sandbox.adapters.wsl.set_version_distro")

return {
  list_distros       = list_distros.list_distros,
  start_distro       = start_distro.start_distro,
  stop_distro        = stop_distro.stop_distro,
  exec_in_distro     = exec_in_distro.exec_in_distro,
  set_default_distro = set_default_distro.set_default_distro,
  set_version_distro = set_version_distro.set_version_distro,
}
