-- Docker Adapter: Functions to connect/disconnect a container to/from a network

local run_argv = require("sandbox.util.run_argv")

local M = {}

--- Connect a container to a network
--- @param network string
--- @param container_id string
--- @return boolean ok, string|nil err
function M.connect_network(network, container_id)
  local ok, output = run_argv.run_blocking_captured({ "docker", "network", "connect", network, container_id })

  if not ok then
    return false, output
  end

  return true, nil
end

--- Disconnect a container from a network
--- @param network string
--- @param container_id string
--- @return boolean ok, string|nil err
function M.disconnect_network(network, container_id)
  local ok, output = run_argv.run_blocking_captured({ "docker", "network", "disconnect", network, container_id })

  if not ok then
    return false, output
  end

  return true, nil
end

return M
