--- Display a list of containers in a vertical split buffer
--- @param containers table[]: List of standardized container objects (id, name, status, image)
return function(containers)
  if type(containers) ~= "table" then
    vim.notify("[nvim-containers] Invalid container list: not a table", vim.log.levels.ERROR)
    return
  end

  local target_bufname = "nvim-containers://container-list"

  -- Check if a buffer with the target name already exists
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_name(buf) == target_bufname then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end

  vim.cmd("vnew")
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_name(buf, target_bufname)

  local lines = {}
  for _, container in ipairs(containers) do
    table.insert(lines, string.format(
      "[%s] %s (%s)",
      container.status or "unknown",
      container.name or "<no name>",
      container.id and container.id:sub(1, 12) or "<no id>"
    ))
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "log"
end
