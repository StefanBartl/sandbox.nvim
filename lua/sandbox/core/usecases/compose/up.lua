-- Use case: Bring a compose project up (detached)
--- @param engine table: must implement up(file, on_done)
--- @param file string
--- @param on_done? fun(ok: boolean, err: string|nil)
return function(engine, file, on_done)
  return engine.up(file, on_done)
end
