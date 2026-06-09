---@module 'containers.core.usecases.wsl.list_distros'

---@param engine WslEngine
---@return WslDistro[]
return function(engine)
  return engine.list_distros()
end
