--- Display a list of containers in a vertical split buffer
--- @param containers table[]: List of standardized container objects (id, name, status, image)
local notify = require("sandbox.notify")
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

  require("lib.nvim.window").open_named_scratch(
    "sandbox.nvim://container-list", lines, { filetype = "log", split = "left" }
  )
end
