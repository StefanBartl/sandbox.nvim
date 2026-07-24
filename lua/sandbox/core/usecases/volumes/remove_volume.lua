-- Use case: Remove a volume
--- @param engine table: must implement remove_volume(name, on_done)
--- @param name string
--- @param on_done? fun(ok: boolean, err: string|nil)
return function(engine, name, on_done)
  return engine.remove_volume(name, on_done)
end
