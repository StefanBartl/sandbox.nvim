--[[
  Docker Adapter Aggregator

  Combines container and image adapters into a full implementation of the
  ContainerEngine port. Merges the sub-aggregators wholesale (rather than
  re-listing every field by hand) so a new container/image method only has
  to be added to containers_engine.lua/images_engine.lua to be reachable
  through sandbox.get_engine() -- a hand-copied field list silently drops
  new methods the moment someone forgets to update it here too.
]]

local containers = require("sandbox.adapters.docker.containers_engine")
local images = require("sandbox.adapters.docker.images_engine")
local volumes = require("sandbox.adapters.docker.volumes_engine")
local networks = require("sandbox.adapters.docker.networks_engine")

return vim.tbl_extend("force", {}, containers, images, volumes, networks)
