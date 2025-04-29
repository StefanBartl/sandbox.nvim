-- Docker Adapter: Function to list all containers (running and stopped)

local M = {}

--- List all containers (running and stopped) using Docker
--- Sorts containers: running first, then others.
--- @return table[]: List of container objects with fields {id, name, status, image}
function M.list_containers()
  local output = vim.fn.system({ "docker", "ps", "-a", "--format", "{{json .}}" })

  if vim.v.shell_error ~= 0 then
    vim.notify("[nvim-containers] Docker error: " .. output, vim.log.levels.ERROR)
    return {}
  end

  local containers = {}

  for _, line in ipairs(vim.split(output, "\n", { trimempty = true })) do
    local ok, container = pcall(vim.fn.json_decode, line)
    if ok and type(container) == "table" then
      table.insert(containers, {
        id = container.ID or "<no id>",
        name = container.Names or "<no name>",
        status = container.State or "unknown",
        image = container.Image or "<no image>",
      })
    else
      vim.notify("[nvim-containers] Docker JSON decode error:\n" .. tostring(line), vim.log.levels.ERROR)
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
