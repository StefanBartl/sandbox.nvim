--- Display logs of a container in a vertical split buffer
--- If a buffer for the container already exists, it will be reused and updated
--- @param lines string[]: Lines of log output
--- @param container_id string: ID or name of the container
return function(lines, container_id)
  local target_bufname = "nvim-containers://logs/" .. container_id
  local buf = nil

  for _, existing_buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(existing_buf) and vim.api.nvim_buf_get_name(existing_buf) == target_bufname then
      buf = existing_buf
      break
    end
  end

  if not buf then
    vim.cmd("vnew")
    buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_name(buf, target_bufname)

    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false
    vim.bo[buf].modifiable = true
    vim.bo[buf].filetype = "log"
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
end

