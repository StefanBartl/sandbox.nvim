-- UI: Simple vertical buffer output for container list

return function(containers)
  vim.cmd("vnew")
  local buf = vim.api.nvim_get_current_buf()
  local lines = {}

  for _, container in ipairs(containers) do
    table.insert(lines, string.format(
      "[%s] %s (%s)",
      container.State or "unknown",
      container.Names and container.Names[1] or "<no name>",
      container.Id:sub(1, 12)
    ))
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
end
