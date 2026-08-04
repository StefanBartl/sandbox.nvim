---@module 'sandbox.core.usecases.registry.login'
--- Authenticate against a registry (password piped via stdin, never argv).
--- @param engine table
--- @param username string
--- @param password string
--- @param registry? string
--- @return boolean ok
--- @return string|nil err
return function(engine, username, password, registry)
  return engine.login_registry(username, password, registry)
end
