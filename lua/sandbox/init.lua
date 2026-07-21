-- Entry point for the plugin

local config = require("sandbox.config")
local notify = require("sandbox.notify")

local engines = {
  podman = require("sandbox.adapters.podman.engine"),
  docker = require("sandbox.adapters.docker.engine"),
}

local M = {}

--- Setup the plugin
--- @param opts table|nil: Optional user configuration
function M.setup(opts)
  config.setup(opts)
end

--- Get the active engine implementation
--- @return table|nil
function M.get_engine()
  local engine = engines[config.options.engine]
  if not engine then
    notify.error("Invalid engine: " .. tostring(config.options.engine))
    return nil
  end
  return engine
end

return M
