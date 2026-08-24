---@module 'sandbox.integrations.menu'
---@brief Context-menu entries for nvzone/menu (soft, opt-in integration).
---@description
--- sandbox.nvim "owns" every list-view buffer it creates (container/image/
--- volume/network), so the trigger lives centrally in
--- `sandbox.ui.list_actions.set_keymaps()` — the one function every list
--- view already calls to bind its row keymaps — rather than being wired
--- per list type. This module is just the reusable item builder that
--- trigger calls into.
---
--- Entries mirror a list view's own `keys` table (the same `{lhs, desc,
--- fn}` shape `list_actions.set_keymaps` takes) one-to-one, so right-click
--- never offers anything the keyboard doesn't already provide. An entry
--- whose action needs an item under the cursor (`no_item` unset) is
--- omitted when nothing resolves there — same rule the keyboard handler
--- already enforces via `item_under_cursor`.
---
--- Self-gating via `config.menu.enable` (config/DEFAULTS.lua, default
--- true) happens in `list_actions.lua`, not here: this module has no
--- config access of its own by design, so it stays a pure builder.

local contextmenu = require("lib.nvim.contextmenu")

local M = {}

---@internal
--- "logs (follow)" -> "Logs (follow)".
---@param desc string
---@return string
local function capitalize(desc)
  return (desc:gsub("^%l", string.upper))
end

--- Build nvzone/menu entries from a list-view's `keys` table, bound to
--- `item` (the row under the cursor, or nil when the cursor isn't on one).
---@param keys Sandbox.ListActions.Keymap[]
---@param item table|nil
---@return Lib.ContextMenu.Item[]
function M.items(keys, item)
  local out = {}
  for _, k in ipairs(keys) do
    local e = contextmenu.entry(k.no_item or item ~= nil, "  " .. capitalize(k.desc), function()
      if k.no_item then
        k.fn()
      else
        k.fn(item)
      end
    end, k.lhs)
    if e then out[#out + 1] = e end
  end
  return out
end

--- Convenience: `items(keys, item)` wrapped as a single nested submenu
--- entry, for hosts that prefer a fly-out. Returns nil when there is
--- nothing to show.
---@param label string
---@param keys Sandbox.ListActions.Keymap[]
---@param item table|nil
---@return Lib.ContextMenu.Item|nil
function M.submenu(label, keys, item)
  return contextmenu.submenu(label, M.items(keys, item))
end

return M
