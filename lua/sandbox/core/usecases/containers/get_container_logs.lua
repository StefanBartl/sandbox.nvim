---@module 'sandbox.core.usecases.containers.get_container_logs'
--- Use Case: Get logs from container
--- @param engine table: must implement get_logs(id: string)
--- @param container_id string
--- @param on_done? fun(...) Passed straight through: when given, the adapter
---        runs asynchronously and delivers the same values to this callback.
--- @return string[]|nil lines, string|nil err
return function(engine, container_id, on_done)
  return engine.get_logs(container_id, on_done)
end
