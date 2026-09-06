---@module 'sandbox.adapters.podman.engine'
--- Podman Adapter Aggregator
---
--- Merges the resource sub-aggregators (containers, images, volumes,
--- networks, registry) wholesale into a full implementation of the
--- ContainerEngine port, rather than re-listing every field by hand -- a
--- new method only has to be added to the matching *_engine.lua to be
--- reachable through sandbox.get_engine(); a hand-copied field list would
--- silently drop it the moment someone forgot to update this file too.

local containers = require("sandbox.adapters.podman.containers_engine")
local images = require("sandbox.adapters.podman.images_engine")
local volumes = require("sandbox.adapters.podman.volumes_engine")
local networks = require("sandbox.adapters.podman.networks_engine")
local registry = require("sandbox.adapters.podman.registry_engine")

return vim.tbl_extend("force", {}, containers, images, volumes, networks, registry)
