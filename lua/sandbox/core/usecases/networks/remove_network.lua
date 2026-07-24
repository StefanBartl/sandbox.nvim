-- Use case: Remove a network
--- @param engine table: must implement remove_network(name, on_done)
--- @param name string
--- @param on_done? fun(ok: boolean, err: string|nil)
return function(engine, name, on_done)
  return engine.remove_network(name, on_done)
end
