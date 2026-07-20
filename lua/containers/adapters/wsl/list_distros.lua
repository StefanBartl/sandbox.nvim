---@module 'containers.adapters.wsl.list_distros'
---@brief Lists all registered WSL distributions and their running state.

local run_argv = require("containers.util.run_argv")
local notify = require("containers.notify")

local M = {}

--- Parses WSL distro list output and returns structured distro info.
--- `wsl --list --verbose` outputs UTF-16 LE on Windows; vim.system decodes it.
---@return WslDistro[]
function M.list_distros()
	local ok, output = run_argv.run_blocking_captured({ "wsl", "--list", "--verbose" })

	if not ok then
		notify.error("WSL list error: " .. output)
		return {}
	end

	-- Strip carriage returns and leading/trailing whitespace introduced by UTF-16 decoding
	output = output:gsub("\r", "")

	local distros = {}

	-- Skip the header line ("  NAME   STATE   VERSION")
	local lines = vim.split(output, "\n", { trimempty = true })
	for i = 2, #lines do
		local line = lines[i]
		-- Leading '*' marks the default distro
		local is_default = line:sub(1, 1) == "*"
		-- Strip the marker and normalize whitespace
		local clean = line:gsub("^%*?%s+", "")
		local name, state = clean:match("^(%S+)%s+(%S+)")
		if name and state then
			distros[#distros + 1] = {
				name = name,
				state = state,
				default = is_default,
			}
		end
	end

	return distros
end

return M
