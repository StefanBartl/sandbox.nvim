---@module 'sandbox.core.usecases.containers.top_container'
--- Use Case: List processes running inside a container
--- @param engine table: must implement top_container(id: string)
--- @param container_id string
--- @param on_done? fun(...) Passed straight through: when given, the adapter
---        runs asynchronously and delivers the same values to this callback.
--- @return string[]|nil lines, string|nil err
return function(engine, container_id, on_done)
  return engine.top_container(container_id, on_done)
end
