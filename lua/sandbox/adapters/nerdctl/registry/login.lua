---@module 'sandbox.adapters.nerdctl.registry.login'
--- Nerdctl Adapter: Authenticate against a registry

local run_argv = require("sandbox.util.run_argv")

local M = {}

--- Log in to a registry. The password is piped via stdin (--password-stdin)
--- rather than passed as an argv element, so it never shows up in the
--- process list or shell history.
--- @param username string
--- @param password string
--- @param registry? string defaults to Docker Hub when omitted
--- @return boolean ok
--- @return string|nil err
function M.login(username, password, registry)
  local args = { "nerdctl", "login", "--username", username, "--password-stdin" }
  if registry and registry ~= "" then
    args[#args + 1] = registry
  end

  local ok, output = run_argv.run_blocking_captured(args, password)
  if not ok then
    return false, output
  end

  return true, nil
end

return M
