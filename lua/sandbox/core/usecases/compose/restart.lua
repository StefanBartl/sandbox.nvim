-- Use case: Restart a compose project
--- @param engine table: must implement restart(file, on_done)
--- @param file string
--- @param on_done? fun(ok: boolean, err: string|nil)
return function(engine, file, on_done)
  return engine.restart(file, on_done)
end
