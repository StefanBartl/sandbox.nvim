-- Use Case: Inspect detailed metadata of a network
--- @param engine table: must implement inspect_network(name)
--- @param name string
--- @return table|string[]
return function(engine, name)
  return engine.inspect_network(name)
end
