--[[
  Docker Image Adapter Aggregator

  Combines all image operations into a unified interface
  for the ContainerEngine port (specific to Docker).
]]

local list_images = require("sandbox.adapters.docker.images.list_images")
local pull_image = require("sandbox.adapters.docker.images.pull_image")
local remove_image = require("sandbox.adapters.docker.images.remove_image")
local prune_images = require("sandbox.adapters.docker.images.prune_images")
local tag_image = require("sandbox.adapters.docker.images.tag_image")
local save_image = require("sandbox.adapters.docker.images.save_image")
local load_image = require("sandbox.adapters.docker.images.load_image")

--- Image operations exposed by the Docker adapter
return {
  list_images = list_images.list_images,
  pull_image = pull_image.pull_image,
  remove_image = remove_image.remove_image,
  prune_images = prune_images.prune_images,
  tag_image = tag_image.tag_image,
  save_image = save_image.save_image,
  load_image = load_image.load_image,
}
