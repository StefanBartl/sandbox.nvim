-- Use case: Remove all unused networks
--- @param engine table: must implement prune_networks(on_done)
--- @param on_done? fun(ok: boolean, err: string|nil)
return function(engine, on_done)
  return engine.prune_networks(on_done)
end
