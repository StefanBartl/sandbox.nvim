-- Use case: Insect a container
--- @param engine table: must implement inspect_container
--- @param container_id string
--- @param on_done? fun(...) Passed straight through: when given, the adapter
---        runs asynchronously and delivers the same values to this callback.
return function(engine, container_id, on_done)
  return engine.inspect_container(container_id, on_done)
end
