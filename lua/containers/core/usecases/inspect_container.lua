-- Use case: Insect a container
--- @param engine table: must implement inspect_container
--- @param container_id string
return function(engine, container_id)
    return engine.inspect_container(container_id)
end
