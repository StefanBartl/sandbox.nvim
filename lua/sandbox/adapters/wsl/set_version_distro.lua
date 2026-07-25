---@module 'sandbox.adapters.wsl.set_version_distro'
---@brief Toggles a WSL distro between WSL1/WSL2 (`wsl --set-version <name> <1|2>`).

local run_argv = require("sandbox.util.run_argv")

local M = {}

---@param name string
---@param version 1|2
---@return boolean ok
---@return string|nil err
function M.set_version_distro(name, version)
	local ok, output = run_argv.run_blocking_captured({ "wsl", "--set-version", name, tostring(version) })

	if not ok then
		return false, output
	end

	return true, nil
end

return M
