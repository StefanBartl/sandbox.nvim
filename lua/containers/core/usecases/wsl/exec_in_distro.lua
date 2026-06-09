---@module 'containers.core.usecases.wsl.exec_in_distro'

---@param engine WslEngine
---@param name string
---@param command string[]|nil
return function(engine, name, command)
  return engine.exec_in_distro(name, command)
end
