---@module 'sandbox.ui.log_follow_view'
--- Stream a container's logs live into a scratch buffer (`logs -f`) instead
--- of a one-shot snapshot. Press `q` to stop following and close the buffer;
--- the underlying process is also killed automatically if the buffer is
--- wiped some other way.

--- @param engine table active ContainerEngine implementation
--- @param container_id string
return function(engine, container_id)
  local list_opts = require("sandbox.config").options
  local bufnr = require("lib.nvim.window").open_named_scratch(
    "sandbox.nvim://logs/" .. container_id,
    { "-- following logs, press q to stop --" },
    { filetype = "log", split = list_opts.list_split, size = list_opts.list_size }
  )
  vim.bo[bufnr].modifiable = false

  local function append(line)
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end
    vim.bo[bufnr].modifiable = true
    vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, { line })
    vim.bo[bufnr].modifiable = false

    local winid = vim.fn.bufwinid(bufnr)
    if winid ~= -1 then
      vim.api.nvim_win_set_cursor(winid, { vim.api.nvim_buf_line_count(bufnr), 0 })
    end
  end

  local handle = engine.follow_logs(container_id, append, function(code)
    if code and code ~= 0 then
      append("-- process exited (" .. code .. ") --")
    end
  end)

  vim.keymap.set("n", "q", function()
    handle.stop()
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end
  end, { buffer = bufnr, desc = "sandbox: stop following logs", nowait = true, silent = true })

  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = bufnr,
    once = true,
    callback = function() handle.stop() end,
  })
end
