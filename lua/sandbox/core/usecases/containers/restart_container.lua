-- Use case: Restart a container
--- @param engine table: must implement restart_container(container_id, on_done)
--- @param container_id string
--- @param on_done? fun(ok: boolean, err: string|nil)
return function(engine, container_id, on_done)
  return engine.restart_container(container_id, on_done)
end
