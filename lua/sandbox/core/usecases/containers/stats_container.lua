-- Use Case: Get a one-shot resource usage snapshot of a container
--- @param engine table: must implement stats_container(id: string)
--- @param container_id string
--- @return string[]|nil lines, string|nil err
return function(engine, container_id)
  return engine.stats_container(container_id)
end
