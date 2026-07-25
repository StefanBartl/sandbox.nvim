-- Podman Adapter: Log out of a registry

local run_argv = require("sandbox.util.run_argv")

local M = {}

--- @param registry? string defaults to Docker Hub when omitted
--- @return boolean ok
--- @return string|nil err
function M.logout(registry)
  local args = { "podman", "logout" }
  if registry and registry ~= "" then
    args[#args + 1] = registry
  end

  local ok, output = run_argv.run_blocking_captured(args)
  if not ok then
    return false, output
  end

  return true, nil
end

return M
