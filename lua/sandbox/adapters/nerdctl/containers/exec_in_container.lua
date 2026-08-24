---@module 'sandbox.adapters.nerdctl.containers.exec_in_container'
--- Nerdctl Adapter: Function to execute a shell command inside a container

local M = {}

local unpack = table.unpack or unpack -- Compatibility for Lua 5.1 and 5.3+

--- Execute a shell or command inside a running container
--- @param container_id string: ID or name of the container
--- @param command string[]?: Command to run inside the container (default: {"sh"})
--- @param workdir string?: Working directory inside the container (`-w`)
function M.exec_in_container(container_id, command, workdir)
  command = command or { "sh" }
  -- `-w` when a working directory was asked for. All three engines spell it
  -- the same, and it has to sit before the container id -- after it, the
  -- flag would be handed to the command running *inside* the container.
  local args = { "nerdctl", "exec", "-it" }
  if type(workdir) == "string" and workdir ~= "" then
    args[#args + 1] = "-w"
    args[#args + 1] = workdir
  end
  args[#args + 1] = container_id
  vim.list_extend(args, command)

  vim.cmd("vnew")
  local buf = vim.api.nvim_get_current_buf()
  vim.fn.termopen(args)
  vim.api.nvim_buf_set_name(buf, "sandbox.nvim://exec/" .. container_id)
  vim.bo[buf].bufhidden = "wipe"

  -- Automatically enter Terminal Insert Mode
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("i", true, false, true), "n", true)
end

return M
