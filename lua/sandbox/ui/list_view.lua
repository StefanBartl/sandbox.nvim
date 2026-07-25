--- Display a list of containers in a vertical split buffer, with
--- buffer-local keymaps to act on the container under the cursor
--- (see `?` inside the buffer, or docs/BINDINGS.md).
--- @param containers table[]: List of standardized container objects (id, name, status, image)
local notify = require("sandbox.notify")
local list_actions = require("sandbox.ui.list_actions")

return function(containers)
  if type(containers) ~= "table" then
    notify.error("Invalid container list: not a table")
    return
  end

  local lines = {}
  for _, container in ipairs(containers) do
    table.insert(lines, string.format(
      "[%s] %s (%s)",
      container.status or "unknown",
      container.name or "<no name>",
      container.id and container.id:sub(1, 12) or "<no id>"
    ))
  end

  local bufnr = require("lib.nvim.window").open_named_scratch(
    "sandbox.nvim://container-list", lines, { filetype = "log", split = "left" }
  )

  local container_cmds = require("sandbox.bindings.usrcmds.container_commands")
  ---@param c table
  local function ref(c) return c.id or c.name end

  list_actions.set_keymaps(bufnr, {
    { lhs = "<CR>", desc = "inspect", fn = function(c) container_cmds.inspect(ref(c)) end },
    { lhs = "i", desc = "inspect", fn = function(c) container_cmds.inspect(ref(c)) end },
    { lhs = "s", desc = "start", fn = function(c) container_cmds.start(ref(c)) end },
    { lhs = "x", desc = "stop", fn = function(c) container_cmds.stop(ref(c)) end },
    { lhs = "X", desc = "kill", fn = function(c) container_cmds.kill(ref(c)) end },
    { lhs = "r", desc = "restart", fn = function(c) container_cmds.restart(ref(c)) end },
    { lhs = "p", desc = "pause", fn = function(c) container_cmds.pause(ref(c)) end },
    { lhs = "P", desc = "unpause", fn = function(c) container_cmds.unpause(ref(c)) end },
    { lhs = "n", desc = "rename", fn = function(c)
        vim.ui.input({ prompt = "New name for " .. (c.name or c.id) .. ": " }, function(new_name)
          if new_name and new_name ~= "" then
            container_cmds.rename(ref(c), new_name)
          end
        end)
      end },
    { lhs = "D", desc = "remove", fn = function(c) container_cmds.remove(ref(c)) end },
    { lhs = "l", desc = "logs", fn = function(c) container_cmds.logs(ref(c)) end },
    { lhs = "e", desc = "exec", fn = function(c) container_cmds.exec(ref(c)) end },
    { lhs = "t", desc = "top", fn = function(c) container_cmds.top(ref(c)) end },
    { lhs = "T", desc = "stats", fn = function(c) container_cmds.stats(ref(c)) end },
    { lhs = "R", desc = "refresh list", no_item = true, fn = function() container_cmds.list() end },
  }, containers, 0)
end
