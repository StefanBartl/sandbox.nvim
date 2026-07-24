-- Podman Adapter: Function to create a volume

local run_argv = require("sandbox.util.run_argv")

local M = {}

--- Create a new named volume
--- @param name string
--- @return boolean ok, string|nil err
function M.create_volume(name)
  local ok, output = run_argv.run_blocking_captured({ "podman", "volume", "create", name })

  if not ok then
    return false, output
  end

  return true, nil
end

return M
