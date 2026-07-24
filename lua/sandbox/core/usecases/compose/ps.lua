-- Use case: List services in a compose project
--- @param engine table: must implement ps(file)
--- @param file string
--- @return string[]|nil lines, string|nil err
return function(engine, file)
  return engine.ps(file)
end
