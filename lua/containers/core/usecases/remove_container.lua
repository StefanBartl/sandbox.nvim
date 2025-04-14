-- Use case: Remove a container
--- @param engine table: must implement remove_container(container_id)
--- @param container_id string
return function(engine, container_id)
  return engine.remove_container(container_id)
end
