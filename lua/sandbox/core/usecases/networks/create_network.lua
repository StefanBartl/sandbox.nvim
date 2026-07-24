-- Use case: Create a new named network
--- @param engine table: must implement create_network(name)
--- @param name string
--- @return boolean ok, string|nil err
return function(engine, name)
  return engine.create_network(name)
end
