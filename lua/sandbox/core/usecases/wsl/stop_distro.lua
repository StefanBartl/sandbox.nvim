---@module 'sandbox.core.usecases.wsl.stop_distro'

---@param engine WslEngine
---@param name string
---@return boolean ok
---@return string|nil err
return function(engine, name)
  return engine.stop_distro(name)
end
