---@module 'containers.core.usecases.wsl.start_distros'

---@param engine WslEngine
---@param name string
---@return boolean
return function(engine, name)
  return engine.start_distro(name)
end
