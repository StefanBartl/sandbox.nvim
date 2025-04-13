-- Use case: List all containers (running or not)

--- @param engine table: must implement list_containers()
--- @return table[]: list of container objects
return function(engine)
  return engine.list_containers()
end
