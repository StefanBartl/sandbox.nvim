---@module 'sandbox.core.usecases.wsl.set_version_distro'

---@param engine WslEngine
---@param name string
---@param version integer 1 or 2
---@return boolean ok
---@return string|nil err
return function(engine, name, version)
  return engine.set_version_distro(name, version)
end
