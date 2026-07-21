---@module 'sandbox.adapters.wsl.stop_distro'
---@brief Terminates a running WSL distribution.

local run_argv = require("sandbox.util.run_argv")

local M = {}

---@param name string
---@return boolean ok
---@return string|nil err
function M.stop_distro(name)
	local ok, output = run_argv.run_blocking_captured({ "wsl", "--terminate", name })

	if not ok then
		return false, output
	end

	return true, nil
end

return M
