--- Display a list of networks in a vertical split buffer, with buffer-local
--- keymaps to act on the network under the cursor (see `?` inside the buffer).
--- @param networks table[]: List of standardized network objects (id, name, driver, scope)
local notify = require("sandbox.notify")
local list_actions = require("sandbox.ui.list_actions")
return function(networks)
  if type(networks) ~= "table" then
    notify.error("Invalid network list: not a table")
    return
  end

  local lines = { string.format("%-15s %-25s %-10s %s", "ID", "NAME", "DRIVER", "SCOPE") }
  lines[#lines + 1] = string.rep("-", 65)
  for _, network in ipairs(networks) do
    lines[#lines + 1] = string.format(
      "%-15s %-25s %-10s %s",
      network.id and network.id:sub(1, 12) or "<no id>",
      network.name or "<no name>",
      network.driver or "<no driver>",
      network.scope or ""
    )
  end

  local list_opts = require("sandbox.config").options
  local bufnr = require("lib.nvim.window").open_named_scratch(
    "sandbox.nvim://network-list", lines,
    { filetype = "log", split = list_opts.list_split, size = list_opts.list_size }
  )

  local network_cmds = require("sandbox.bindings.usrcmds.network_commands")
  ---@param n table
  local function ref(n) return n.name or n.id end

  list_actions.set_keymaps(bufnr, {
    { lhs = "<CR>", desc = "inspect", fn = function(n) network_cmds.inspect(ref(n)) end },
    { lhs = "i", desc = "inspect", fn = function(n) network_cmds.inspect(ref(n)) end },
    { lhs = "D", desc = "remove", fn = function(n) network_cmds.remove(ref(n)) end },
    { lhs = "R", desc = "refresh list", no_item = true, fn = function() network_cmds.list() end },
  }, networks, 2)

  list_actions.set_visual_bulk_actions(bufnr, {
    { lhs = "D", desc = "remove selection", fn = function(selected)
        list_actions.bulk_confirm_then("Remove", "network", selected, ref, network_cmds.remove)
      end },
  }, networks, 2)

  list_actions.setup_autorefresh(bufnr, network_cmds.list)
end
