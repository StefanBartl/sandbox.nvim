--- @param data table | string[]
--- @param container_id string
return function(data, container_id)
  local lines = {}

  if type(data) == "table" then
    lines = vim.split(vim.inspect(data), "\n", { plain = true })
  else
    lines = data -- already an error string[]
  end

  vim.cmd("vnew")
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_name(buf, "nvim-containers://inspect/" .. container_id)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  vim.bo[buf].filetype = "lua"
  vim.bo[buf].modifiable = false
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
end
