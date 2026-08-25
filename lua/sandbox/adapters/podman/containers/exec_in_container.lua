---@module 'sandbox.adapters.podman.containers.exec_in_container'
--- Podman Adapter: Execute a command inside a running container

local M = {}

--- Execute a command inside a container
--- Opens a vertical split window with a terminal session inside the specified container.
---
--- @param container_id string: ID or name of the container
--- @param command string[]|nil: Optional command to execute inside the container (default is { "sh" })
function M.exec_in_container(container_id, command, workdir)
  command = command or { "sh" }

  -- `-w` when a working directory was asked for. All three engines spell it
  -- the same, and it has to sit before the container id -- after it, the
  -- flag would be handed to the command running *inside* the container.
  local args = { "podman", "exec", "-it" }
  if type(workdir) == "string" and workdir ~= "" then
    args[#args + 1] = "-w"
    args[#args + 1] = workdir
  end
  args[#args + 1] = container_id
  vim.list_extend(args, command)

  vim.cmd("vnew")

  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_name(buf, "sandbox.nvim://exec/" .. container_id)

  vim.fn.termopen(args)

  vim.bo[buf].bufhidden = "wipe"

  -- Explicitly set the current buffer and enter terminal insert mode
  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("i", true, false, true), "n", true)
end

return M
