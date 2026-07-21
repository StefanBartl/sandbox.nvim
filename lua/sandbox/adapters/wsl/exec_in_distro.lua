---@module 'sandbox.adapters.wsl.exec_in_distro'
---@brief Opens an interactive shell or runs a command inside a WSL distro.

local M = {}

---@diagnostic disable-next-line
local unpack = table.unpack or unpack
local api = vim.api

---@param name string
---@param command string[]|nil Optional command; defaults to the distro's default shell.
function M.exec_in_distro(name, command)
	local args

	if command and #command > 0 then
		-- Explicit command: wsl -d <name> -- <cmd> [args...]
		args = { "wsl", "-d", name, "--", unpack(command) }
	else
		-- No command: drops into the default login shell of the distro
		args = { "wsl", "-d", name }
	end

	vim.cmd("vnew")
	local buf = vim.api.nvim_get_current_buf()
	api.nvim_buf_set_name(buf, "sandbox.nvim://wsl/" .. name)
	vim.fn.termopen(args)
	vim.bo[buf].bufhidden = "wipe"
	api.nvim_set_current_buf(buf)
	api.nvim_feedkeys(vim.api.nvim_replace_termcodes("i", true, false, true), "n", true)
end

return M
