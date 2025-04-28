-- Podman Adapter: Function to retrieve the logs of a container

local M = {}

--- Retrieve the logs of a specific container
--- @param container_id string: ID or name of the container to retrieve logs from
--- @return string[]: List of log lines, or an error message if the operation fails
function M.get_logs(container_id)
  local output = vim.fn.system({ "podman", "logs", container_id })

  if vim.v.shell_error ~= 0 then
    vim.notify("Podman logs error: " .. output, vim.log.levels.ERROR)
    return { "[nvim-containers] Failed to get logs for: " .. container_id }
  end

  return vim.split(output, "\n", { plain = true })
end

return M

