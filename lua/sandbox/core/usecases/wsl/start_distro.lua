---@module 'sandbox.core.usecases.wsl.start_distro'

---@param engine WslEngine
---@param name string
---@return boolean ok
---@return string|nil err
return function(engine, name)
  return engine.start_distro(name)
end
