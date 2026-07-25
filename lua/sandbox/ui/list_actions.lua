--- Shared buffer-local keymap wiring for read-only list-view scratch buffers,
--- so a key on the line under the cursor can act on that item directly
--- instead of re-typing `:Sandbox <kind> <action> <id>` by hand.
local M = {}

---@param items table[] items in the same order as the rendered lines
---@param header_offset integer|nil number of leading non-item lines
---@return table|nil
function M.item_under_cursor(items, header_offset)
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local idx = lnum - (header_offset or 0)
  return items[idx]
end

---@class Sandbox.ListActions.Keymap
---@field lhs string
---@field desc string
---@field fn function called with the item under cursor, or with no args when `no_item` is set
---@field no_item? boolean set for buffer-wide actions that don't need a cursor item

---@param bufnr integer
---@param keys Sandbox.ListActions.Keymap[]
---@param items table[]
---@param header_offset integer|nil
function M.set_keymaps(bufnr, keys, items, header_offset)
  for _, k in ipairs(keys) do
    vim.keymap.set("n", k.lhs, function()
      if k.no_item then
        k.fn()
        return
      end
      local item = M.item_under_cursor(items, header_offset)
      if not item then
        require("sandbox.notify").warn("No item on this line")
        return
      end
      k.fn(item)
    end, { buffer = bufnr, desc = "sandbox: " .. k.desc, nowait = true, silent = true })
  end

  vim.keymap.set("n", "q", function()
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end, { buffer = bufnr, desc = "sandbox: close list buffer", nowait = true, silent = true })

  vim.keymap.set("n", "?", function()
    local lines = { "sandbox.nvim keymaps:" }
    for _, k in ipairs(keys) do
      lines[#lines + 1] = string.format("  %-6s %s", k.lhs, k.desc)
    end
    lines[#lines + 1] = "  q      close this buffer"
    require("sandbox.notify").info(table.concat(lines, "\n"))
  end, { buffer = bufnr, desc = "sandbox: show keymaps", nowait = true, silent = true })
end

return M
