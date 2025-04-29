-- Healthcheck for nvim-containers.nvim

local config = require("containers.config")
local health = vim.health
local engine_utils = require("containers.engine_utils")

local M = {}

--- Perform plugin health check
function M.check()
  health.start("nvim-containers.nvim healthcheck")

  local engine = config.options.engine

  -- Check if engine is set
  if not engine then
    health.error("No container engine configured (nil)")
    return
  end

  -- Validate engine value
  if engine ~= "podman" and engine ~= "docker" then
    health.error("Invalid container engine configured: " .. tostring(engine))
    return
  else
    health.ok("Container engine configured: " .. engine)
  end

  -- Check if engine CLI exists
  if engine_utils.is_executable(engine) then
    health.ok(engine .. " CLI executable found")
  else
    health.error(engine .. " CLI executable not found in PATH")
  end
end

return M
