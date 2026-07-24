--- Display a list of volumes in a vertical split buffer
--- @param volumes table[]: List of standardized volume objects (name, driver, mountpoint)
local notify = require("sandbox.notify")
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

  require("lib.nvim.window").open_named_scratch(
    "sandbox.nvim://volume-list", lines, { filetype = "log", split = "left" }
  )
end
