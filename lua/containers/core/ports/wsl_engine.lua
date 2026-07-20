---@module 'containers.core.ports.wsl_engine'
---@brief Defines the expected interface for WSL distro management.
---@description
--- This port describes the operations available for managing WSL distributions.
--- It is intentionally separate from the ContainerEngine port, as WSL distros
--- do not share the same semantics as OCI containers (no images, no logs, no inspect).

return {
  --- @return WslDistro[]|nil distros, string|nil err
  list_distros = function()
    error("list_distros not implemented")
  end,
  --- @param name string
  --- @return boolean ok, string|nil err
  start_distro = function(name)
    error(name .. ": start_distro not implemented")
  end,
  --- @param name string
  --- @return boolean ok, string|nil err
  stop_distro = function(name)
    error(name .. ": stop_distro not implemented")
  end,
  exec_in_distro = function(name, command)
    error(name .. ": exec_in_distro not implemented. Command: " .. vim.inspect(command))
  end,
}
