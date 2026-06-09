---@module 'containers.adapters.wsl.stop_distro'
---@brief Terminates a running WSL distribution.

local M = {}

---@param name string
---@return boolean
function M.stop_distro(name)
	local output = vim.fn.system({ "wsl", "--terminate", name })

	if vim.v.shell_error ~= 0 then
		vim.notify("[nvim-containers] WSL terminate error for '" .. name .. "': " .. output, vim.log.levels.ERROR)
		return false
	end

	return true
end

return M
