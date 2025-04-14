-- Use case: Start a container
--- @param engine table: must implement start_container(container_id)
--- @param container_id string
return function(engine, container_id)
  return engine.start_container(container_id)
end
