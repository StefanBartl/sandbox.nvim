--[[
  Docker Volume Adapter Aggregator

  Combines all volume operations into a unified interface
  for the ContainerEngine port (specific to Docker).
]]

local list_volumes = require("sandbox.adapters.docker.volumes.list_volumes")
local create_volume = require("sandbox.adapters.docker.volumes.create_volume")
local remove_volume = require("sandbox.adapters.docker.volumes.remove_volume")
local inspect_volume = require("sandbox.adapters.docker.volumes.inspect_volume")
local prune_volumes = require("sandbox.adapters.docker.volumes.prune_volumes")

--- Volume operations exposed by the Docker adapter
return {
  list_volumes = list_volumes.list_volumes,
  create_volume = create_volume.create_volume,
  remove_volume = remove_volume.remove_volume,
  inspect_volume = inspect_volume.inspect_volume,
  prune_volumes = prune_volumes.prune_volumes,
}
