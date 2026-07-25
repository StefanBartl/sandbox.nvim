---@module 'sandbox.core.usecases.wsl.shutdown_all'

---@param engine WslEngine
---@return boolean ok
---@return string|nil err
return function(engine)
  return engine.shutdown_all()
end
