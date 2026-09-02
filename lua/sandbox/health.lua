---@module 'sandbox.health'
--- Healthcheck for sandbox.nvim

local config = require("sandbox.config")
local health = vim.health
local engine_utils = require("sandbox.engine_utils")

local M = {}

--- Perform plugin health check
function M.check()
  health.start("sandbox.nvim healthcheck")

  local engine = config.options.engine

  -- Check if engine is set
  if not engine then
    health.error("No container engine configured (nil)")
    return
  end

  -- Validate engine value
  if engine ~= "podman" and engine ~= "docker" and engine ~= "nerdctl" then
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

  -- WSL availability check (informational, not an error if absent)
  if engine_utils.is_executable("wsl") then
    health.ok("WSL executable found – WslList/WslStart/WslStop/WslExec commands available")
  else
    health.info("WSL not found in PATH – WSL commands not registered (expected on Linux/macOS)")
  end

  -- The hover integration can be absent for three unrelated reasons, and none
  -- of them says anything at the point of use: the float simply never opens.
  -- Naming which one is the whole value of reporting it here.
  if config.options.hover == false then
    health.info("Hover integration disabled (opts.hover = false)")
  elseif not pcall(require, "hover.registry") then
    health.info("hover.nvim not installed – image previews unavailable (optional)")
  elseif require("sandbox.hover").registered() then
    health.ok("hover.nvim image preview registered – ask for it with :Hover show")
  else
    health.warn(
      "hover.nvim is installed but does not support request-only contributions, "
        .. "so the image preview was not registered: an engine call costs "
        .. "300-750 ms and would stutter the automatic trigger. Update hover.nvim."
    )
  end

  require("lib.nvim.bindings.usercmd.composer").checkhealth("Sandbox")
end

return M
