-- Adapter: Podman implementation of ContainerEngine interface

local M = {}

--- List all containers (running or stopped)
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

  return result
end

return M
