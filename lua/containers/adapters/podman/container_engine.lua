-- Adapter: Podman implementation of ContainerEngine interface

local M = {}

--- List all containers (running or stopped)
--- @return table[]
function M.list_containers()
  local output = vim.fn.systemlist({"podman", "ps", "-a", "--format", "json"})
  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to list Podman containers", vim.log.levels.ERROR)
    return {}
  end
  local json = table.concat(output, "\n")
  local ok, result = pcall(vim.fn.json_encode, json)
  if not ok then
    vim.notify("Error parsing podman output: " .. result, vim.log.levels.ERROR)
    return {}
  end
  return result
end

return M
