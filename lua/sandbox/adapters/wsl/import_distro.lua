---@module 'sandbox.adapters.wsl.import_distro'
---@brief Imports a WSL distro from a tarball (`wsl --import <name> <install-dir> <tar-path>`).

local run_argv = require("sandbox.util.run_argv")

local M = {}

---@param name string new distro name
---@param install_path string directory the distro's VHD will be installed into
---@param tar_path string source .tar file path
---@return boolean ok
---@return string|nil err
function M.import_distro(name, install_path, tar_path)
	local ok, output = run_argv.run_blocking_captured({ "wsl", "--import", name, install_path, tar_path })

	if not ok then
		return false, output
	end

	return true, nil
end

return M
