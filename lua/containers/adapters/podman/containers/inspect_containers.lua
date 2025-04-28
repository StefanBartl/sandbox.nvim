local M = {}

function M.inspect_container(container_id)
  local output = vim.fn.system({ "podman", "inspect", container_id })

  local ok, result = pcall(vim.fn.json_decode, output)
  if not ok or type(result) ~= "table" then
    return { "[nvim-containers] Invalid JSON output:\n" .. output }
  end

  if vim.v.shell_error ~= 0 or result[1] == nil then
    return { "[nvim-containers] Error inspecting container:\n" .. output }
  end

  return result[1]
end

return M
