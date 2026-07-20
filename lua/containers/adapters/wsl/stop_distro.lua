---@module 'containers.adapters.wsl.stop_distro'
---@brief Terminates a running WSL distribution.

local run_argv = require("containers.util.run_argv")
local notify = require("containers.notify")

local M = {}

---@param name string
---@return boolean
function M.stop_distro(name)
	local ok, output = run_argv.run_blocking_captured({ "wsl", "--terminate", name })

	if not ok then
		notify.error("WSL terminate error for '" .. name .. "': " .. output)
		return false
	end

	return true
end

return M
