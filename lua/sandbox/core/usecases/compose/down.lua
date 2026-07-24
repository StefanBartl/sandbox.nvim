-- Use case: Stop and remove a compose project
--- @param engine table: must implement down(file, on_done)
--- @param file string
--- @param on_done? fun(ok: boolean, err: string|nil)
return function(engine, file, on_done)
  return engine.down(file, on_done)
end
