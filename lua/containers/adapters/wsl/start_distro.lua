---@module 'containers.adapters.wsl.start_distro'
---@brief Starts a WSL distro by launching a no-op command inside it.
---@description
--- WSL has no explicit "start" command. Launching any process in a stopped
--- distro brings it to Running state. A no-op `echo` is used for this purpose.

local M = {}

---@param name string
---@return boolean
function M.start_distro(name)
	-- WSL distros start implicitly when a command is executed inside them.
	-- Running `echo` is the canonical no-op start trigger.
	local output = vim.fn.system({ "wsl", "-d", name, "--", "echo" })

	if vim.v.shell_error ~= 0 then
		vim.notify("[nvim-containers] WSL start error for '" .. name .. "': " .. output, vim.log.levels.ERROR)
		return false
	end

	return true
end

return M
