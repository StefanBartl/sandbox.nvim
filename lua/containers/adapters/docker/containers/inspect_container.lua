-- Docker Adapter: Function to inspect a container

local M = {}

--- Inspect a specific container and return its detailed metadata
--- @param container_id string: ID or name of the container to inspect
--- @return table|string[]: Container metadata as a table, or error message as string[]
function M.inspect_container(container_id)
  -- Run docker inspect command
  local output = vim.fn.system({ "docker", "inspect", container_id })

  -- Try to decode JSON output
  local ok, result = pcall(vim.fn.json_decode, output)
  if not ok or type(result) ~= "table" then
    return { "[nvim-containers] Invalid JSON output:\n" .. output }
  end

  -- Handle shell errors or missing result
  if vim.v.shell_error ~= 0 or result[1] == nil then
    return { "[nvim-containers] Error inspecting container:\n" .. output }
  end

  return result[1]
end

return M
