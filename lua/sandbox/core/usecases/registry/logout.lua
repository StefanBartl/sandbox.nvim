---@module 'sandbox.core.usecases.registry.logout'
--- Log out of a registry.
--- @param engine table
--- @param registry? string
--- @return boolean ok
--- @return string|nil err
return function(engine, registry)
  return engine.logout_registry(registry)
end
