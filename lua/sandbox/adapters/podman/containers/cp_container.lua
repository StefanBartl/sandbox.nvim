-- Podman Adapter: Function to copy files/directories between host and container

local run_argv = require("sandbox.util.run_argv")

local M = {}

--- Copy a file or directory between the host and a container.
--- Either src or dest must be in "container:path" form, matching `podman cp`.
--- @param src string
--- @param dest string
--- @return boolean ok, string|nil err
function M.cp_container(src, dest)
  local ok, output = run_argv.run_blocking_captured({ "podman", "cp", src, dest })

  if not ok then
    return false, output
  end

  return true, nil
end

return M
