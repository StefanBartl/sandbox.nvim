-- Use case: Create a new named volume
--- @param engine table: must implement create_volume(name)
--- @param name string
--- @return boolean ok, string|nil err
return function(engine, name)
  return engine.create_volume(name)
end
