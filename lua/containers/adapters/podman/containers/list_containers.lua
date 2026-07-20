-- Podman Adapter: Function to list all containers

local run_argv = require("containers.util.run_argv")

local M = {}

--- List all containers (running and stopped) using Podman
--- Sorts containers: running first, then others.
--- @return table[]|nil containers, string|nil err
function M.list_containers()
  local ok, output = run_argv.run_blocking_captured({ "podman", "ps", "-a", "--format", "json" })

  if not ok then
    return nil, output
  end

  local decode_ok, result = pcall(vim.fn.json_decode, output)
  if not decode_ok then
    return nil, result
  end

  local containers = {}
  for _, container in ipairs(result) do
    table.insert(containers, {
      id = container.Id,
      name = container.Names and container.Names[1] or "<no name>",
      status = container.State,
      image = container.Image,
    })
  end

  table.sort(containers, function(a, b)
    if a.status == b.status then
      return a.name < b.name
    elseif a.status == "running" then
      return true
    elseif b.status == "running" then
      return false
    else
      return a.name < b.name
    end
  end)

  return containers, nil
end

return M
