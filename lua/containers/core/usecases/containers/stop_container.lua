-- Use case: Stop a container
--- @param engine table: must implement stop_container(container_id)
--- @param container_id string
return function(engine, container_id)
  return engine.stop_container(container_id)
end
