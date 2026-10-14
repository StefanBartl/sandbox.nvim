---@module 'sandbox.util.exec_target'
--- Where `container exec` / `exec-once` open their terminal session. By default a vertical split
--- with a plain terminal job (every adapter's own code). With `exec_target = "terminal"` the same
--- `<engine> exec -it ...` argv becomes the job of a terminal.nvim terminal named after the
--- container, so the session can be hidden and toggled back, survives a layout change and shows
--- up in terminal.nvim's list, status and sessions.
---
--- terminal.nvim is a soft dependency: asked only when the option is set, and a missing or older
--- one is reported once and the split is used instead.

local M = {}

local warned = false

--- Hand `args` to terminal.nvim when the option asks for it.
---@param args string[] The full argv, e.g. `{ "docker", "exec", "-it", id, "sh" }`
---@param container_id string
---@return boolean handled # false: the caller opens its split as before
function M.open(args, container_id)
  if require("sandbox.config").options.exec_target ~= "terminal" then
    return false
  end
  local loaded, terminal = pcall(require, "terminal")
  if not loaded or type(terminal.run) ~= "function" then
    if not warned then
      warned = true
      require("sandbox.notify").warn('exec_target = "terminal" needs terminal.nvim; using a split')
    end
    return false
  end
  local started, err = terminal.run(args, {
    direct = true,
    name = "sandbox:" .. container_id,
    close = "never",
  })
  if started == false then
    require("sandbox.notify").warn(("terminal.nvim could not open the session: %s"):format(tostring(err)))
    return false
  end
  return true
end

return M
