local M = {}

--- Start a specific container
--- @param container_id string: ID or name of the container to start
--- @return boolean: true if successful, false if an error occurred
function M.start_container(container_id)
  local output = vim.fn.system({ "podman", "start", container_id })

  if vim.v.shell_error ~= 0 then
    vim.notify("Podman start error: " .. output, vim.logd.levels.ERROR)
    return false
  end

  return true
end

return M
