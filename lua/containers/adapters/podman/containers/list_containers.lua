-- Podman Adapter: Function to list all containers

local M = {}

--- List all containers (running and stopped) using Podman
--- @return table[]: List of containers, each as a standardized object (id, name, status, image)
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

  return containers
end

return M
