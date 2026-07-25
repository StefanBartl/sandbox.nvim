---@module 'sandbox.adapters.wsl.export_distro'
---@brief Exports a WSL distro to a tarball on disk (`wsl --export <name> <path>`).

local run_argv = require("sandbox.util.run_argv")

local M = {}

---@param name string
---@param path string destination .tar file path
---@return boolean ok
---@return string|nil err
function M.export_distro(name, path)
	local ok, output = run_argv.run_blocking_captured({ "wsl", "--export", name, path })

	if not ok then
		return false, output
	end

	return true, nil
end

return M
