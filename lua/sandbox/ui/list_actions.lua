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
local autocmd = require("lib.nvim.bindings.autocmd")
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
---@field lhs string|string[] the default key(s)
---@field desc string  # also the action's name, slugified ("logs (follow)" -> `logs_follow`)
---@field fn function called with the item under cursor, or with no args when `no_item` is set
---@field no_item? boolean set for buffer-wide actions that don't need a cursor item

---@internal
--- "logs (follow)" -> "logs_follow": the action name a user writes in
--- `keymaps.<kind>` to move or drop that key.
---@param desc string
---@return string
local function slug(desc)
  return (desc:lower():gsub("[^%w]+", "_"):gsub("^_+", ""):gsub("_+$", ""))
end

---@internal
--- The user's overrides for one list kind, or nil.
---@param surface string
---@return table|false|nil
local function user_overrides(surface)
  local cfg = require("sandbox.config").options.keymaps
  if cfg == false then
    return false
  end
  if type(cfg) ~= "table" then
    return nil
  end
  local v = cfg[surface]
  if type(v) == "table" or v == false then
    return v
  end
  return nil
end

---@internal
--- Turn a view's `keys` table into registry actions.
---
--- Entries sharing a `desc` become ONE action with several default keys --
--- every list binds `<CR>` and `i` to "inspect", which is one thing a user
--- would want to move, not two.
---@param keys Sandbox.ListActions.Keymap[]
---@param wrap fun(k: Sandbox.ListActions.Keymap): function
---@param mode string
---@return table<string, Lib.Keymap.Action> actions
---@return string[] order
---@return table<string, Sandbox.ListActions.Keymap> by_name
local function actions_from(keys, wrap, mode)
  local actions, order, by_name = {}, {}, {}
  for _, k in ipairs(keys) do
    local name = slug(k.desc)
    local existing = actions[name]
    if existing then
      -- Same action, another default key.
      local list = type(existing.default) == "table" and existing.default or { existing.default }
      list[#list + 1] = k.lhs
      existing.default = list
    else
      actions[name] = {
        default = k.lhs,
        desc = k.desc,
        mode = mode,
        rhs = wrap(k),
        opts = { nowait = true, silent = true },
      }
      order[#order + 1] = name
      by_name[name] = k
    end
  end
  return actions, order, by_name
end

---@internal
--- The `keys` table again, with the lhs the user actually ended up with and
--- without the actions they switched off.
---
--- The right-click menu and the `?` help both read this rather than the
--- declared defaults: an entry advertising a key that is no longer bound is
--- worse than no entry at all.
---@param bound Lib.Keymap.Registered[]
---@param by_name table<string, Sandbox.ListActions.Keymap>
---@return Sandbox.ListActions.Keymap[]
local function resolved_keys(bound, by_name)
  local out, seen = {}, {}
  for _, e in ipairs(bound) do
    if e.bound and e.lhs and not seen[e.name] and by_name[e.name] then
      seen[e.name] = true
      local k = by_name[e.name]
      out[#out + 1] = { lhs = e.lhs, desc = k.desc, fn = k.fn, no_item = k.no_item }
    end
  end
  return out
end

--- Bind one list view's row keymaps, plus the four every list shares.
---
--- Declared through `lib.nvim.bindings.keymap`'s registry, so each is a named
--- action a user can move or drop:
--- `keymaps = { containers = { remove = false } }`. The names come from the
--- descriptions -- "logs (follow)" is `logs_follow` -- and the shared
--- `q`/`E`/`f`/`?` live under `keymaps.list`, since they are the same four
--- keys in every list rather than four per kind.
---@param bufnr integer
---@param keys Sandbox.ListActions.Keymap[]
---@param items table[]
---@param header_offset integer|nil
---@param opts? { surface?: string, refresh?: function, filter?: fun(query: string) }
---@return nil
function M.set_keymaps(bufnr, keys, items, header_offset, opts)
  opts = type(opts) == "table" and opts or {}
  local surface = opts.surface or "list"
  local keymap = require("lib.nvim.bindings.keymap")

  ---@param k Sandbox.ListActions.Keymap
  ---@return function
  local function row_action(k)
    return function()
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
    end
  end

  local actions, order, by_name = actions_from(keys, row_action, "n")
  local bound = keymap.register(
    "sandbox",
    { order = order, actions = actions },
    user_overrides(surface),
    { buffer = bufnr, surface = surface }
  )
  local live = resolved_keys(bound, by_name)

  ---@type Lib.Keymap.Registered[]
  local shared_bound

  ---@type table<string, Lib.Keymap.Action>
  local shared = {
    close = {
      default = "q",
      desc = "close list buffer",
      opts = { nowait = true, silent = true },
      rhs = function()
        vim.api.nvim_buf_delete(bufnr, { force = true })
      end,
    },

    -- Engine switch from inside the list. Reaching `:Sandbox engine set podman`
    -- meant leaving the buffer, typing the command and reopening -- three steps
    -- for something you decide while looking at the very list that would change.
    engine = {
      default = "E",
      desc = "cycle container engine",
      opts = { nowait = true, silent = true },
      rhs = function()
        require("sandbox.bindings.usrcmds.engine_commands").cycle()
        -- Re-render if the view told us how; otherwise the switch is applied
        -- and the next open shows it.
        if type(opts.refresh) == "function" then
          opts.refresh()
        end
      end,
    },

    help = {
      default = "?",
      desc = "show keymaps",
      opts = { nowait = true, silent = true },
      rhs = function()
        local lines = { "sandbox.nvim keymaps:" }
        for _, k in ipairs(live) do
          lines[#lines + 1] = string.format("  %-6s %s", k.lhs, k.desc)
        end
        for _, e in ipairs(shared_bound or {}) do
          if e.bound and e.lhs then
            lines[#lines + 1] = string.format("  %-6s %s", e.lhs, e.desc or e.name)
          end
        end
        require("sandbox.notify").info(table.concat(lines, "\n"))
      end,
    },
  }

  -- Structured filter. `/` is Vim's own buffer search, which finds a line but
  -- leaves every other one on screen; this narrows the list to what matches,
  -- across every field of an item rather than just the rendered text. Only
  -- declared where the view knows how to filter itself.
  if type(opts.filter) == "function" then
    shared.filter = {
      default = "f",
      desc = "filter this list",
      opts = { nowait = true, silent = true },
      rhs = function()
        require("lib.nvim.ui.kit").input({
          title = "filter: ",
          on_submit = function(query)
            opts.filter(vim.trim(query or ""))
          end,
        })
      end,
    }
  end

  shared_bound = keymap.register(
    "sandbox",
    { order = { "close", "engine", "filter", "help" }, actions = shared },
    user_overrides("list"),
    { buffer = bufnr, surface = surface .. "/shared" }
  )

  local menu_cfg = require("sandbox.config").options.menu
  if not menu_cfg or menu_cfg.enable ~= false then
    contextmenu.bind_buffer(bufnr, function()
      local item = M.item_under_cursor(items, header_offset)
      return require("sandbox.integrations.menu").items(live, item)
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

--- The single `q`-closes key the non-list scratch views use.
---
--- A named action like everything else here, so it can be moved or dropped
--- via `keymaps.<surface>.close` -- `q` is a fine default for a read-only
--- buffer and a poor one for anybody who records macros.
---@param bufnr integer
---@param surface string  # "inspect" or "logs"
---@param desc string
---@param before? fun(): nil  # runs before the buffer goes (stopping a stream)
---@return nil
function M.bind_close(bufnr, surface, desc, before)
  require("lib.nvim.bindings.keymap").register("sandbox", {
    order = { "close" },
    actions = {
      close = {
        default = "q",
        desc = desc,
        opts = { nowait = true, silent = true },
        rhs = function()
          if before then
            before()
          end
          if vim.api.nvim_buf_is_valid(bufnr) then
            vim.api.nvim_buf_delete(bufnr, { force = true })
          end
        end,
      },
    },
  }, user_overrides(surface), { buffer = bufnr, surface = surface })
end

--- Bind bulk actions triggered from a Visual-mode selection (multi-select),
--- e.g. select several stopped containers with `V`/`j`/`j`/... then hit `D`
--- to remove them all instead of reaching for `prune`. `fn` receives every
--- item spanned by the selection.
---
--- Named actions like the row keymaps, under their own surface: overriding
--- `keymaps.containers.remove` moves the normal-mode key and
--- `keymaps.containers_visual.remove_selection` the visual one, because they
--- are two keys a user may well want in two different places.
---@param bufnr integer
---@param keys { lhs: string, desc: string, fn: fun(items: table[]) }[]
---@param items table[]
---@param header_offset integer|nil
---@param surface? string  # list kind; the visual set is stored as `<kind>_visual`
---@return nil
function M.set_visual_bulk_actions(bufnr, keys, items, header_offset, surface)
  surface = (surface or "list") .. "_visual"

  ---@param k table
  ---@return function
  local function bulk(k)
    return function()
      local selected = M.items_in_visual_selection(items, header_offset)
      -- Return to Normal mode; the mapping replaces the builtin visual
      -- action (delete/etc.) so nothing else exits Visual mode for us.
      vim.cmd("normal! \27")
      if #selected == 0 then
        require("sandbox.notify").warn("No items in selection")
        return
      end
      k.fn(selected)
    end
  end

  local actions, order = actions_from(keys, bulk, "x")
  require("lib.nvim.bindings.keymap").register(
    "sandbox",
    { order = order, actions = actions },
    user_overrides(surface),
    { buffer = bufnr, surface = surface }
  )
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

  -- Name what is about to go. The question used to read "Remove 5
  -- containers?" and stop there, which is the one question a confirmation
  -- for a *bulk* action must not leave open -- a Visual selection is easy to
  -- get one line wrong, and the answer is irreversible.
  --
  -- Capped, because a selection can be long and a prompt that scrolls is no
  -- better than no list at all.
  local MAX_SHOWN = 10
  local shown = {}
  for i = 1, math.min(#items, MAX_SHOWN) do
    shown[#shown + 1] = "  " .. tostring(ref(items[i]))
  end
  if #items > MAX_SHOWN then
    shown[#shown + 1] = ("  … and %d more"):format(#items - MAX_SHOWN)
  end

  local question =
    string.format("%s %d %s%s?\n%s", label, #items, noun, #items > 1 and "s" or "", table.concat(shown, "\n"))

  confirm.destructive(question, function()
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

  autocmd.create("BufWipeout", function()
    if not timer:is_closing() then
      timer:stop()
      timer:close()
    end
  end, {
    group = autocmd.group("sandbox_ui"),
    buffer = bufnr,
    once = true,
    desc = "[sandbox] Stop a list view's refresh timer when its buffer is wiped",
  })
end

return M
