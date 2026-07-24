-- Use case: Connect a container to a network
--- @param engine table: must implement connect_network(network, container_id)
--- @param network string
--- @param container_id string
--- @return boolean ok, string|nil err
return function(engine, network, container_id)
  return engine.connect_network(network, container_id)
end
