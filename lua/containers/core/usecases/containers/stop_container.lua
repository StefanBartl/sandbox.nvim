-- Use case: Stop a container
--- @param engine table: must implement stop_container(container_id, on_done)
--- @param container_id string
--- @param on_done? fun(ok: boolean, err: string|nil)
return function(engine, container_id, on_done)
  return engine.stop_container(container_id, on_done)
end
