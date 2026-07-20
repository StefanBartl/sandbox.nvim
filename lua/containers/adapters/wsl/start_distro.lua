---@module 'containers.adapters.wsl.start_distro'
---@brief Starts a WSL distro by launching a no-op command inside it.
---@description
--- WSL has no explicit "start" command. Launching any process in a stopped
--- distro brings it to Running state. A no-op `echo` is used for this purpose.

local run_argv = require("containers.util.run_argv")
local notify = require("containers.notify")

local M = {}

---@param name string
---@return boolean
function M.start_distro(name)
	-- WSL distros start implicitly when a command is executed inside them.
	-- Running `echo` is the canonical no-op start trigger.
	local ok, output = run_argv.run_blocking_captured({ "wsl", "-d", name, "--", "echo" })

	if not ok then
		notify.error("WSL start error for '" .. name .. "': " .. output)
		return false
	end

	return true
end

return M
