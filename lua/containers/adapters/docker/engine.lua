--[[
  Docker Adapter Aggregator

  Combines container and image adapters into a full implementation of the ContainerEngine port.
]]

local containers = require("containers.adapters.docker.containers_engine")
local images_engine = require("containers.adapters.docker.images_engine") -- <--- richtig images_engine.lua laden!

--- Docker operations exposed by the Docker adapter
return {
  -- Container operations
  list_containers     = containers.list_containers,
  get_logs            = containers.get_logs,
  exec_in_container   = containers.exec_in_container,
  start_container     = containers.start_container,
  stop_container      = containers.stop_container,
  kill_container      = containers.kill_container,
  remove_container    = containers.remove_container,
  prune_containers    = containers.prune_containers,
  inspect_container   = containers.inspect_container,

  -- Image operations
  list_images         = images_engine.list_images,
  pull_image          = images_engine.pull_image,
  remove_image        = images_engine.remove_image,
  prune_images        = images_engine.prune_images,
}
