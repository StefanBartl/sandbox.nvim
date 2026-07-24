-- Use case: Pause a container's processes
--- @param engine table: must implement pause_container(container_id, on_done)
--- @param container_id string
--- @param on_done? fun(ok: boolean, err: string|nil)
return function(engine, container_id, on_done)
  return engine.pause_container(container_id, on_done)
end
