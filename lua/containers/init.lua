-- Entry point for the plugin

local config = require("containers.config")

local engines = {
  podman = require("containers.adapters.podman.container_engine"),
  -- docker = require("containers.adapters.docker.container_engine"), -- planned
}

local M = {}

function M.setup(opts)
  config.setup(opts)
end

function M.get_engine()
  return engines[config.options.engine]
end

return M

