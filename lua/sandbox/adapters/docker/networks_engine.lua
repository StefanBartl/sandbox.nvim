--[[
  Docker Network Adapter Aggregator

  Combines all network operations into a unified interface
  for the ContainerEngine port (specific to Docker).
]]

local list_networks = require("sandbox.adapters.docker.networks.list_networks")
local create_network = require("sandbox.adapters.docker.networks.create_network")
local remove_network = require("sandbox.adapters.docker.networks.remove_network")
local inspect_network = require("sandbox.adapters.docker.networks.inspect_network")
local connect_network = require("sandbox.adapters.docker.networks.connect_network")
local prune_networks = require("sandbox.adapters.docker.networks.prune_networks")

--- Network operations exposed by the Docker adapter
return {
  list_networks = list_networks.list_networks,
  create_network = create_network.create_network,
  remove_network = remove_network.remove_network,
  inspect_network = inspect_network.inspect_network,
  connect_network = connect_network.connect_network,
  disconnect_network = connect_network.disconnect_network,
  prune_networks = prune_networks.prune_networks,
}
