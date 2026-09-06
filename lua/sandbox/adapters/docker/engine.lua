---@module 'sandbox.adapters.docker.engine'
--- Docker Adapter Aggregator
---
--- Merges the resource sub-aggregators (containers, images, volumes,
--- networks, registry) wholesale into a full implementation of the
--- ContainerEngine port, rather than re-listing every field by hand -- a
--- new method only has to be added to the matching *_engine.lua to be
--- reachable through sandbox.get_engine(); a hand-copied field list would
--- silently drop it the moment someone forgot to update this file too.

local containers = require("sandbox.adapters.docker.containers_engine")
local images = require("sandbox.adapters.docker.images_engine")
local volumes = require("sandbox.adapters.docker.volumes_engine")
local networks = require("sandbox.adapters.docker.networks_engine")
local registry = require("sandbox.adapters.docker.registry_engine")

return vim.tbl_extend("force", {}, containers, images, volumes, networks, registry)
