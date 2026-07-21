-- Healthcheck for sandbox.nvim

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

	-- WSL availability check (informational, not an error if absent)
	if engine_utils.is_executable("wsl") then
		health.ok("WSL executable found – WslList/WslStart/WslStop/WslExec commands available")
	else
		health.info("WSL not found in PATH – WSL commands not registered (expected on Linux/macOS)")
	end
end

return M
