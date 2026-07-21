--- Use Case: Get logs from container
--- @param engine table: must implement get_logs(id: string)
--- @param container_id string
--- @return string[]|nil lines, string|nil err
return function(engine, container_id)
  return engine.get_logs(container_id)
end
