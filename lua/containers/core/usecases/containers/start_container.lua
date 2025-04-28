--- Use case: Start a container
--- @param engine table: must implement start_container(container_id)
--- @param container_id string: ID of the container to start
--- @return boolean: true if started successfully, false otherwise
return function(engine, container_id)
  return engine.start_container(container_id)
end
