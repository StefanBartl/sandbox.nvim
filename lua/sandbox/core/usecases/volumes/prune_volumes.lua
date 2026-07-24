-- Use case: Remove all unused volumes
--- @param engine table: must implement prune_volumes(on_done)
--- @param on_done? fun(ok: boolean, err: string|nil)
return function(engine, on_done)
  return engine.prune_volumes(on_done)
end
