-- Use case: List all containers (running or not)

--- @param engine table: must implement list_containers()
--- @return table[]|nil containers, string|nil err
return function(engine)
  return engine.list_containers()
end
