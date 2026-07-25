---@module 'sandbox.adapters.wsl.shutdown_all'
---@brief Shuts down the WSL2 VM and all running distros (`wsl --shutdown`),
--- distinct from stopping a single named distro.

local run_argv = require("sandbox.util.run_argv")

local M = {}

---@return boolean ok
---@return string|nil err
function M.shutdown_all()
	local ok, output = run_argv.run_blocking_captured({ "wsl", "--shutdown" })

	if not ok then
		return false, output
	end

	return true, nil
end

return M
