--[[
  Nerdctl Image Adapter Aggregator

  Combines all image operations into a unified interface
  for the ContainerEngine port (specific to Nerdctl).
]]

local list_images = require("sandbox.adapters.nerdctl.images.list_images")
local pull_image = require("sandbox.adapters.nerdctl.images.pull_image")
local push_image = require("sandbox.adapters.nerdctl.images.push_image")
local remove_image = require("sandbox.adapters.nerdctl.images.remove_image")
local prune_images = require("sandbox.adapters.nerdctl.images.prune_images")
local tag_image = require("sandbox.adapters.nerdctl.images.tag_image")
local save_image = require("sandbox.adapters.nerdctl.images.save_image")
local load_image = require("sandbox.adapters.nerdctl.images.load_image")
local history_image = require("sandbox.adapters.nerdctl.images.history_image")
local inspect_image = require("sandbox.adapters.nerdctl.images.inspect_image")

--- Image operations exposed by the Nerdctl adapter
return {
  list_images = list_images.list_images,
  pull_image = pull_image.pull_image,
  push_image = push_image.push_image,
  remove_image = remove_image.remove_image,
  prune_images = prune_images.prune_images,
  tag_image = tag_image.tag_image,
  save_image = save_image.save_image,
  load_image = load_image.load_image,
  history_image = history_image.history_image,
  inspect_image = inspect_image.inspect_image,
}
