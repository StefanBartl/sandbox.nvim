--- Display a list of volumes in a vertical split buffer, with buffer-local
--- keymaps to act on the volume under the cursor (see `?` inside the buffer).
--- @param volumes table[]: List of standardized volume objects (name, driver, mountpoint)
local notify = require("sandbox.notify")
local list_actions = require("sandbox.ui.list_actions")
return function(volumes)
  if type(volumes) ~= "table" then
    notify.error("Invalid volume list: not a table")
    return
  end

  local lines = { string.format("%-30s %-10s %s", "NAME", "DRIVER", "MOUNTPOINT") }
  lines[#lines + 1] = string.rep("-", 70)
  for _, volume in ipairs(volumes) do
    lines[#lines + 1] = string.format(
      "%-30s %-10s %s",
      volume.name or "<no name>",
      volume.driver or "<no driver>",
      volume.mountpoint or ""
    )
  end

  local list_opts = require("sandbox.config").options
  local bufnr = require("lib.nvim.window").open_named_scratch(
    "sandbox.nvim://volume-list", lines,
    { filetype = "log", split = list_opts.list_split, size = list_opts.list_size }
  )

  local volume_cmds = require("sandbox.bindings.usrcmds.volume_commands")
  list_actions.set_keymaps(bufnr, {
    { lhs = "<CR>", desc = "inspect", fn = function(v) volume_cmds.inspect(v.name) end },
    { lhs = "i", desc = "inspect", fn = function(v) volume_cmds.inspect(v.name) end },
    { lhs = "D", desc = "remove", fn = function(v) volume_cmds.remove(v.name) end },
    { lhs = "R", desc = "refresh list", no_item = true, fn = function() volume_cmds.list() end },
  }, volumes, 2)
end
