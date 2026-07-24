-- Use Case: Inspect detailed metadata of a volume
--- @param engine table: must implement inspect_volume(name)
--- @param name string
--- @return table|string[]
return function(engine, name)
  return engine.inspect_volume(name)
end
