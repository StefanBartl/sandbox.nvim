-- Use Case: List processes running inside a container
--- @param engine table: must implement top_container(id: string)
--- @param container_id string
--- @return string[]|nil lines, string|nil err
return function(engine, container_id)
  return engine.top_container(container_id)
end
