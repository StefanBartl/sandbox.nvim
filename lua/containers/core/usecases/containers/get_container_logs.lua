--- Use Case: Getlogs from container
--- @param engine table: must implement get_logs(id: string): string[]
--- @param container_id string
--- @return string[]
return function(engine, container_id)
  return engine.get_logs(container_id)
end
