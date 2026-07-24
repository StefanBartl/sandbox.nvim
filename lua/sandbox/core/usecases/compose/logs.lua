-- Use case: Show logs for a compose project
--- @param engine table: must implement logs(file)
--- @param file string
--- @return string[]|nil lines, string|nil err
return function(engine, file)
  return engine.logs(file)
end
