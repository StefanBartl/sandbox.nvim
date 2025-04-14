local function format_size(bytes)
  bytes = tonumber(bytes)
  if not bytes then return "?" end
  if bytes < 1024 then return bytes .. " B" end
  if bytes < 1024^2 then return string.format("%.1f KB", bytes / 1024) end
  if bytes < 1024^3 then return string.format("%.1f MB", bytes / 1024^2) end
  return string.format("%.1f GB", bytes / 1024^3)
end

--- Render a list of container images in a new buffer
--- @param images table[]
return function(images)
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
    local size = format_size(img.Size or 0)

    table.insert(lines, string.format("%-26s %-11s %-15s %s", repo, tag, id, size))
  end

  vim.cmd("vnew")
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_name(buf, "nvim-containers://images")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
end
