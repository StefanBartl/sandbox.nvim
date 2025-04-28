--[[
  Podman Image Adapter

  Implements image-related operations of the ContainerEngine port
  for Podman: list, pull, remove, prune
]]

local list_images = require("containers.adapters.podman.images.list_images")
local pull_image = require("containers.adapters.podman.images.pull_image")
local remove_image = require("containers.adapters.podman.images.remove_image")
local prune_images = require("containers.adapters.podman.images.prune_images")

--- Image operations exposed by the Podman adapter
return {
  list_images = list_images.list_images,
  pull_image = pull_image.pull_image,
  remove_image = remove_image.remove_image,
  prune_images = prune_images.prune_images,
}
