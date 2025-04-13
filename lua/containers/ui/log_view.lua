--- @param lines string[]
--- @param container_id string
return function(lines, container_id)
  vim.cmd("vnew")
  local buf = vim.api.nvim_get_current_buf()

  vim.api.nvim_buf_set_name(buf, "nvim-containers://logs/" .. container_id)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  vim.bo[buf].filetype = "log"
  vim.bo[buf].modifiable = false
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
end
