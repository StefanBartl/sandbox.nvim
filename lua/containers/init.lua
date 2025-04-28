-- Entry point for the plugin

local config = require("containers.config")

local engines = {
  podman = require("containers.adapters.podman.engine"),
  docker = require("containers.adapters.docker.engine"),
}

local M = {}

function M.setup(opts)
  config.setup(opts)
end

function M.get_engine()
  local engine = engines[config.options.engine]
  if not engine then
    vim.notify("[nvim-containers] Invalid engine: " .. tostring(config.options.engine), vim.log.levels.ERROR)
    return nil
  end
  return engine
end

return M

