-- Podman Adapter: Execute a command inside a running container

local M = {}

-- Compatibility fix for Lua versions:
-- 'unpack' is available as 'table.unpack' in newer Lua versions
local unpack = table.unpack or unpack

--- Execute a command inside a container
--- Opens a vertical split window with a terminal session inside the specified container.
---
--- @param container_id string: ID or name of the container
--- @param command string[]|nil: Optional command to execute inside the container (default is { "sh" })
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
