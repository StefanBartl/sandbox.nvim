--- View for listing all Docker or Podman images
--- @param images table[]
return function(images)
  if type(images) ~= "table" then
    vim.notify("[nvim-containers] Invalid image list: not a table", vim.log.levels.ERROR)
    return
  end

  vim.cmd("vnew")
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_name(buf, "nvim-containers://image-list")

  local lines = {}
  for _, image in ipairs(images) do
    table.insert(lines, string.format(
      "[%s:%s] %s (%s)",
      image.repository or "<none>",
      image.tag or "<none>",
      image.id and image.id:sub(1, 12) or "<no id>",
      image.size or "unknown size"
    ))
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "log"
end
