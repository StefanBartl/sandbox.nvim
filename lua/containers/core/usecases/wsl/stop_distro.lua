---@module 'containers.core.usecases.wsl.stop_distro'

---@param engine WslEngine
---@param name string
---@return boolean
return function(engine, name)
  return engine.stop_distro(name)
end
