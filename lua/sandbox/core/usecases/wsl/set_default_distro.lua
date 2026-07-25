---@module 'sandbox.core.usecases.wsl.set_default_distro'

---@param engine WslEngine
---@param name string
---@return boolean ok
---@return string|nil err
return function(engine, name)
  return engine.set_default_distro(name)
end
