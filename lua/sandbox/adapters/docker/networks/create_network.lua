-- Docker Adapter: Function to create a network

local run_argv = require("sandbox.util.run_argv")

local M = {}

--- Create a new named network
--- @param name string
--- @return boolean ok, string|nil err
function M.create_network(name)
  local ok, output = run_argv.run_blocking_captured({ "docker", "network", "create", name })

  if not ok then
    return false, output
  end

  return true, nil
end

return M
