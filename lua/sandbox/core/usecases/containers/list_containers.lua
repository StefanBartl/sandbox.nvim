---@module 'sandbox.core.usecases.containers.list_containers'
--- Use case: List all containers (running or not)

--- @param engine table: must implement list_containers()
--- @param on_done? fun(...) Passed straight through: when given, the adapter
---        runs asynchronously and delivers the same values to this callback.
--- @return table[]|nil containers, string|nil err
return function(engine, on_done)
  return engine.list_containers(on_done)
end
