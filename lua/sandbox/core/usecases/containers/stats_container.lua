---@module 'sandbox.core.usecases.containers.stats_container'
--- Use Case: Get a one-shot resource usage snapshot of a container
--- @param engine table: must implement stats_container(id: string)
--- @param container_id string
--- @param on_done? fun(...) Passed straight through: when given, the adapter
---        runs asynchronously and delivers the same values to this callback.
--- @return string[]|nil lines, string|nil err
return function(engine, container_id, on_done)
  return engine.stats_container(container_id, on_done)
end
