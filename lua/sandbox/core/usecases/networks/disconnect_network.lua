-- Use case: Disconnect a container from a network
--- @param engine table: must implement disconnect_network(network, container_id)
--- @param network string
--- @param container_id string
--- @return boolean ok, string|nil err
return function(engine, network, container_id)
  return engine.disconnect_network(network, container_id)
end
