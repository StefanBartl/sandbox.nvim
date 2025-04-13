-- Adapter: Podman implementation of ContainerEngine interface

local M = {}
local unpack = table.unpack or unpack -- for backwards comptability

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

function M.get_logs(container_id)
  local output = vim.fn.system({"podman", "logs", container_id})

  if vim.v.shell_error ~= 0 then
    vim.notify("Podman logs error: " .. output, vim.logs.levels.ERROR)
    return { "[nvim-containers] Failed to get logs for: " .. container_id}
  end
  return vim.split(output, "\n", { plain = true })
end

function M.exec_in_container(container_id, command)
  command = command or { "sh" }
  local args = { "podman", "exec", "-it", container_id, unpack(command) }

  vim.cmd("vnew")
  local buf = vim.api.nvim_get_current_buf()
  vim.fn.termopen(args)
  vim.api.nvim_buf_set_name(buf, "nvim-containers://exec/" .. container_id)
  vim.bo[buf].bufhidden = "wipe"
end

return M
