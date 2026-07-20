---@module 'containers.core.usecases.wsl.list_distros'

---@param engine WslEngine
---@return WslDistro[]|nil distros
---@return string|nil err
return function(engine)
  return engine.list_distros()
end
