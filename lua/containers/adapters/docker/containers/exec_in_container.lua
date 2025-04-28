-- Docker Adapter: Function to execute a shell command inside a container

local M = {}

local unpack = table.unpack or unpack -- Compatibility for Lua 5.1 and 5.3+

--- Execute a shell or command inside a running container
--- @param container_id string: ID or name of the container
--- @param command string[]?: Command to run inside the container (default: {"sh"})
function M.exec_in_container(container_id, command)
  command = command or { "sh" }
  local args = { "docker", "exec", "-it", container_id, unpack(command) }

  vim.cmd("vnew")
  local buf = vim.api.nvim_get_current_buf()
  vim.fn.termopen(args)
  vim.api.nvim_buf_set_name(buf, "nvim-containers://exec/" .. container_id)
  vim.bo[buf].bufhidden = "wipe"
end

return M
