-- Use case: List all volumes
--- @param engine table: must implement list_volumes()
--- @return table[]|nil volumes, string|nil err
return function(engine)
  return engine.list_volumes()
end
