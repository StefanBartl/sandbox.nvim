-- Docker Adapter: Function to get a one-shot resource usage snapshot of a container

local run_argv = require("sandbox.util.run_argv")

local M = {}

--- Get a one-shot CPU/memory/network/block-IO snapshot of a container
--- @param container_id string: ID or name of the container
--- @return string[]|nil lines, string|nil err
function M.stats_container(container_id)
  local ok, output = run_argv.run_blocking_captured({ "docker", "stats", "--no-stream", container_id })

  if not ok then
    return nil, output
  end

  return vim.split(output, "\n", { plain = true }), nil
end

return M
