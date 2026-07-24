-- Use case: Rename a container
--- @param engine table: must implement rename_container(container_id, new_name)
--- @param container_id string
--- @param new_name string
--- @return boolean ok, string|nil err
return function(engine, container_id, new_name)
  return engine.rename_container(container_id, new_name)
end
