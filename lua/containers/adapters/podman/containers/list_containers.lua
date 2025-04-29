-- Podman Adapter: Function to list all containers

local M = {}

--- List all containers (running and stopped) using Podman
--- Sorts containers: running first, then others.
--- @return table[]: List of containers (each with id, name, status, image)
function M.list_containers()
  local output = vim.fn.system({ "podman", "ps", "-a", "--format", "json" })

  if vim.v.shell_error ~= 0 then
    vim.notify("Podman error: " .. output, vim.log.levels.ERROR)
    return {}
  end

  local ok, result = pcall(vim.fn.json_decode, output)
  if not ok then
    vim.notify("JSON decode error: " .. result, vim.log.levels.ERROR)
    return {}
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

  return containers
end

return M
