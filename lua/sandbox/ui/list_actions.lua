---@module 'sandbox.ui.list_actions'
--- Shared buffer-local keymap wiring for read-only list-view scratch buffers,
--- so a key on the line under the cursor can act on that item directly
--- instead of re-typing `:Sandbox <kind> <action> <id>` by hand.
---
--- Also binds a `<RightMouse>` context menu (nvzone/menu, soft dependency;
--- entries from sandbox.integrations.menu) mirroring these same keymaps —
--- every list view calls `M.set_keymaps` to bind its rows, so the menu
--- trigger comes along for free instead of needing separate wiring per
--- list type. Gated on `config.menu.enable` (default true); a missing
--- nvzone/menu install degrades to a no-op, never an error.
local contextmenu = require("lib.nvim.contextmenu")

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

  local menu_cfg = require("sandbox.config").options.menu
  if not menu_cfg or menu_cfg.enable ~= false then
    contextmenu.bind_buffer(bufnr, function()
      local item = M.item_under_cursor(items, header_offset)
      return require("sandbox.integrations.menu").items(keys, item)
    end, { desc = "sandbox: right-click context menu" })
  end
end

--- Items covered by the CURRENT visual selection. Must be called from
--- inside a Visual-mode keymap callback, while still in Visual mode: the
--- `'<`/`'>` marks are only updated once Visual mode is actually exited
--- (e.g. via `<Esc>`), so a Lua-function mapping bound in mode "x" -- which
--- runs its callback *before* that happens (`mode()` still reports
--- "v"/"V"/"" at that point) -- must instead read the live selection via
--- `getpos("v")` (where Visual mode started) and `getpos(".")` (the cursor).
---@param items table[]
---@param header_offset integer|nil
---@return table[]
function M.items_in_visual_selection(items, header_offset)
  local start_line = vim.fn.getpos("v")[2]
  local end_line = vim.fn.getpos(".")[2]
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end

  local selected = {}
  for lnum = start_line, end_line do
    local item = items[lnum - (header_offset or 0)]
    if item then
      selected[#selected + 1] = item
    end
  end
  return selected
end

--- Bind bulk actions triggered from a Visual-mode selection (multi-select),
--- e.g. select several stopped containers with `V`/`j`/`j`/... then hit `D`
--- to remove them all instead of reaching for `prune`. `fn` receives every
--- item spanned by the selection.
---@param bufnr integer
---@param keys { lhs: string, desc: string, fn: fun(items: table[]) }[]
---@param items table[]
---@param header_offset integer|nil
function M.set_visual_bulk_actions(bufnr, keys, items, header_offset)
  for _, k in ipairs(keys) do
    vim.keymap.set("x", k.lhs, function()
      local selected = M.items_in_visual_selection(items, header_offset)
      -- Return to Normal mode; the mapping replaces the builtin visual
      -- action (delete/etc.) so nothing else exits Visual mode for us.
      vim.cmd("normal! \27")
      if #selected == 0 then
        require("sandbox.notify").warn("No items in selection")
        return
      end
      k.fn(selected)
    end, { buffer = bufnr, desc = "sandbox: " .. k.desc .. " (selection)", nowait = true, silent = true })
  end
end

--- Confirm once for a whole batch (instead of once per item), then call
--- `fn(id)` for every item with `config.options.confirm_destructive`
--- temporarily suppressed -- so a per-item command function that already
--- confirms internally (container_cmds.remove, image_cmds.remove, ...)
--- doesn't re-prompt for each item in the selection.
---@param label string e.g. "Remove"
---@param noun string e.g. "container"
---@param items table[]
---@param ref fun(item: table): string
---@param fn fun(id: string)
function M.bulk_confirm_then(label, noun, items, ref, fn)
  local confirm = require("sandbox.util.confirm")
  confirm.destructive(string.format("%s %d %s%s?", label, #items, noun, #items > 1 and "s" or ""), function()
    local config = require("sandbox.config")
    local prev = config.options.confirm_destructive
    config.options.confirm_destructive = false
    for _, item in ipairs(items) do
      fn(ref(item))
    end
    config.options.confirm_destructive = prev
  end)
end

--- Periodically re-run `refresh_fn` (e.g. `container_commands.list`) while
--- `bufnr` is visible in a window, governed by `config.options.refresh_interval`
--- (ms; nil/0 disables). Safe to call on every render since `open_named_scratch`
--- reuses the same bufnr — a buffer-local flag stops a second timer being armed.
---@param bufnr integer
---@param refresh_fn function
function M.setup_autorefresh(bufnr, refresh_fn)
  local interval = require("sandbox.config").options.refresh_interval
  if not interval or interval <= 0 then
    return
  end
  if vim.b[bufnr].sandbox_autorefresh_active then
    return
  end
  vim.b[bufnr].sandbox_autorefresh_active = true

  local timer = vim.uv.new_timer()
  timer:start(
    interval,
    interval,
    vim.schedule_wrap(function()
      if not vim.api.nvim_buf_is_valid(bufnr) or vim.fn.bufwinid(bufnr) == -1 then
        if not timer:is_closing() then
          timer:stop()
          timer:close()
        end
        return
      end
      refresh_fn()
    end)
  )

  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = bufnr,
    once = true,
    callback = function()
      if not timer:is_closing() then
        timer:stop()
        timer:close()
      end
    end,
  })
end

return M
