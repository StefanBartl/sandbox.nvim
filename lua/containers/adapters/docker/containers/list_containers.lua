-- Docker Adapter: Function to list all containers (running and stopped)

local run_argv = require("containers.util.run_argv")
local notify = require("containers.notify")

local M = {}

--- List all containers (running and stopped) using Docker
--- Sorts containers: running first, then others.
--- @return table[]: List of container objects with fields {id, name, status, image}
function M.list_containers()
  local ok, output = run_argv.run_blocking_captured({ "docker", "ps", "-a", "--format", "{{json .}}" })

  if not ok then
    notify.error("Docker error: " .. output)
    return {}
  end

  local containers = {}

  for _, line in ipairs(vim.split(output, "\n", { trimempty = true })) do
    local decode_ok, container = pcall(vim.fn.json_decode, line)
    if decode_ok and type(container) == "table" then
      table.insert(containers, {
        id = container.ID or "<no id>",
        name = container.Names or "<no name>",
        status = container.State or "unknown",
        image = container.Image or "<no image>",
      })
    else
      notify.error("Docker JSON decode error:\n" .. tostring(line))
    end
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

  return containers
end

return M
