-- UI: Simple vertical buffer output for container list

return function(containers)
  if type(containers) ~= "table" then
    vim.notify("[nvim-containers] Invalid container list: not a table", vim.log.levels.ERROR)
    return
  end

  vim.cmd("vnew")
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_name(buf, "nvim-containers://container-list")
  local lines = {}

  for _, container in ipairs(containers) do
    table.insert(lines, string.format(
      "[%s] %s (%s)",
      container.State or "unknown",
      container.Names and container.Names[1] or "<no name>",
      container.Id and container.Id:sub(1, 12) or "<no id>"
    ))
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "log"
end
