--[[
  Docker Image Adapter Aggregator

  Combines all image operations into a unified interface
  for the ContainerEngine port (specific to Docker).
]]

local list_images = require("containers.adapters.docker.images.list_images")
local pull_image = require("containers.adapters.docker.images.pull_image")
local remove_image = require("containers.adapters.docker.images.remove_image")
local prune_images = require("containers.adapters.docker.images.prune_images")

--- Image operations exposed by the Docker adapter
return {
  list_images = list_images.list_images,
  pull_image = pull_image.pull_image,
  remove_image = remove_image.remove_image,
  prune_images = prune_images.prune_images,
}
