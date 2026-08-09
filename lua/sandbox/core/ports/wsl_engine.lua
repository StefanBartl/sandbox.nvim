---@module 'sandbox.core.ports.wsl_engine'
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
  --- @param name string
  --- @return boolean ok, string|nil err
  set_default_distro = function(name)
    error(name .. ": set_default_distro not implemented")
  end,
  --- @param name string
  --- @param version integer 1 or 2
  --- @return boolean ok, string|nil err
  set_version_distro = function(name, version)
    error(name .. ": set_version_distro not implemented. version: " .. tostring(version))
  end,
  --- @param name string
  --- @param path string destination .tar file path
  --- @return boolean ok, string|nil err
  export_distro = function(name, path)
    error(name .. ": export_distro not implemented. path: " .. tostring(path))
  end,
  --- @param name string new distro name
  --- @param install_path string directory the distro's VHD will be installed into
  --- @param tar_path string source .tar file path
  --- @return boolean ok, string|nil err
  import_distro = function(name, install_path, tar_path)
    error(
      name
        .. ": import_distro not implemented. install_path: "
        .. tostring(install_path)
        .. " tar_path: "
        .. tostring(tar_path)
    )
  end,
  --- @return boolean ok, string|nil err
  shutdown_all = function()
    error("shutdown_all not implemented")
  end,
}
