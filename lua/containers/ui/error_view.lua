-- file: lua/containers/ui/error_view.lua

--- Display an error message in a new split buffer
--- @param lines string[]  -- error lines to show
return function(lines)
  vim.cmd("belowright new") -- open horizontal split
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_name(buf, "nvim-containers://error-view")

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "log"
end
