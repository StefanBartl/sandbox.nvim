-- Use case: Resume a paused container's processes
--- @param engine table: must implement unpause_container(container_id, on_done)
--- @param container_id string
--- @param on_done? fun(ok: boolean, err: string|nil)
return function(engine, container_id, on_done)
  return engine.unpause_container(container_id, on_done)
end
