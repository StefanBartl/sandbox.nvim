-- Docker Adapter: Function to list all containers (running and stopped)

local run_argv = require("containers.util.run_argv")

local M = {}

--- List all containers (running and stopped) using Docker
--- Sorts containers: running first, then others.
--- @return table[]|nil containers, string|nil err
function M.list_containers()
  local ok, output = run_argv.run_blocking_captured({ "docker", "ps", "-a", "--format", "{{json .}}" })

  if not ok then
    return nil, "Docker error: " .. output
  end

  local containers = {}
  local decode_errors = {}

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
      table.insert(decode_errors, tostring(line))
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

  if #decode_errors > 0 then
    return containers, "Docker JSON decode error(s):\n" .. table.concat(decode_errors, "\n")
  end

  return containers, nil
end

return M
