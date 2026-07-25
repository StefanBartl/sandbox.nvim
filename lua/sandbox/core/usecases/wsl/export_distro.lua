---@module 'sandbox.core.usecases.wsl.export_distro'

---@param engine WslEngine
---@param name string
---@param path string
---@return boolean ok
---@return string|nil err
return function(engine, name, path)
  return engine.export_distro(name, path)
end
