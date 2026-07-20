--- Render a list of container images in a new buffer
--- @param images table[]
return function(images)
  local format_bytes = require("lib.lua.strings.format").format_bytes
  local lines = {}

  table.insert(lines, "REPOSITORY                 TAG         IMAGE ID        SIZE")
  table.insert(lines, string.rep("-", 65))

  for _, img in ipairs(images) do
    -- Parse repo:tag from Names[1]
    local name = (img.Names or {})[1] or "<none>:<none>"
    local repo, tag = name:match("^(.-):([^:]+)$")
    repo = repo or "<none>"
    tag = tag or "<none>"

    local id = (img.Id or ""):sub(1, 12)
    local size = format_bytes(tonumber(img.Size) or 0)

    table.insert(lines, string.format("%-26s %-11s %-15s %s", repo, tag, id, size))
  end

  require("lib.nvim.window").open_named_scratch(
    "sandbox.nvim://images", lines, { filetype = "markdown", split = "left" }
  )
end
