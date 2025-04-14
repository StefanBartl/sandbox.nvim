-- Use case: Kill a container
--- @param engine table: must implement kill_container(container_id)
--- @param container_id string
return function(engine, container_id)
  return engine.kill_container(container_id)
end
