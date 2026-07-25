---@module 'sandbox.core.usecases.wsl.import_distro'

---@param engine WslEngine
---@param name string
---@param install_path string
---@param tar_path string
---@return boolean ok
---@return string|nil err
return function(engine, name, install_path, tar_path)
  return engine.import_distro(name, install_path, tar_path)
end
