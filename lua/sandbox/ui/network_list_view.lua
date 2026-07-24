--- Display a list of networks in a vertical split buffer
--- @param networks table[]: List of standardized network objects (id, name, driver, scope)
local notify = require("sandbox.notify")
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

  require("lib.nvim.window").open_named_scratch(
    "sandbox.nvim://network-list", lines, { filetype = "log", split = "left" }
  )
end
