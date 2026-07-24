-- Use case: List all networks
--- @param engine table: must implement list_networks()
--- @return table[]|nil networks, string|nil err
return function(engine)
  return engine.list_networks()
end
