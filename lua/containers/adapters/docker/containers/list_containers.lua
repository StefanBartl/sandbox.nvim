-- Docker Adapter: Function to list all containers (running and stopped)

local M = {}

--- List all containers (running and stopped) using Docker
--- @return table[]: List of container objects with fields {id, name, status, image}
function M.list_containers()
  -- Run docker ps with JSON output
  local output = vim.fn.system({ "docker", "ps", "-a", "--format", "{{json .}}" })

  -- Check if docker command failed
  if vim.v.shell_error ~= 0 then
    vim.notify("[nvim-containers] Docker error: " .. output, vim.log.levels.ERROR)
    return {}
  end

  local containers = {}

  -- Parse each line as a separate JSON object
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

  return containers
end

return M
