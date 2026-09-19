-- `list_actions.set_keymaps` is what makes a list view a list view: it turns a
-- view's `{lhs, desc, fn}` table into named actions in lib.nvim's keymap
-- registry, adds the four keys every list shares (`q`/`E`/`f`/`?`), and binds
-- the right-click menu to the same set.
--
-- `list_actions_spec.lua` next to this file covers the Visual-mode multi-select
-- machinery through real feedkeys. This one covers the rest: the naming rule a
-- user's `keymaps = { … }` spec depends on, the shared keys, the `?` listing,
-- the menu gate, and `setup_autorefresh`'s timer lifecycle.
--
-- Everything runs against real buffers and the real registry -- lib.nvim and
-- ui.nvim are both available here -- with only the command modules replaced.
---@diagnostic disable: need-check-nil

--- @param lines string[]
--- @return integer bufnr
local function buffer_with(lines)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_open_win(bufnr, true, { relative = "editor", width = 40, height = 10, row = 0, col = 0 })
  return bufnr
end

--- @param bufnr integer
--- @param mode string
--- @return table<string, string> lhs -> desc
local function keymaps_of(bufnr, mode)
  local out = {}
  for _, map in ipairs(vim.api.nvim_buf_get_keymap(bufnr, mode)) do
    out[map.lhs] = map.desc or ""
  end
  return out
end

--- @param keys string
local function press(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "x", false)
end

describe("ui.list_actions.item_under_cursor", function()
  after_each(function()
    vim.cmd("silent! %bwipeout!")
  end)

  local items = { { name = "a" }, { name = "b" }, { name = "c" } }

  it("maps line N to item N without a header", function()
    buffer_with({ "one", "two", "three" })
    local list_actions = require("sandbox.ui.list_actions")

    vim.api.nvim_win_set_cursor(0, { 2, 0 })
    assert.are.equal(items[2], list_actions.item_under_cursor(items, 0))
  end)

  it("subtracts the header offset", function()
    buffer_with({ "HEADER", "-----", "one", "two", "three" })
    local list_actions = require("sandbox.ui.list_actions")

    vim.api.nvim_win_set_cursor(0, { 3, 0 })
    assert.are.equal(items[1], list_actions.item_under_cursor(items, 2))

    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    assert.is_nil(list_actions.item_under_cursor(items, 2))
  end)

  it("treats a missing offset as zero", function()
    buffer_with({ "one", "two" })
    local list_actions = require("sandbox.ui.list_actions")

    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    assert.are.equal(items[1], list_actions.item_under_cursor(items, nil))
  end)

  it("is nil past the end of the list", function()
    buffer_with({ "one", "two", "three", "four" })
    local list_actions = require("sandbox.ui.list_actions")

    vim.api.nvim_win_set_cursor(0, { 4, 0 })
    assert.is_nil(list_actions.item_under_cursor(items, 0))
  end)
end)

describe("ui.list_actions.set_keymaps", function()
  local notices
  local cycled

  --- @param user_keymaps any value for config.options.keymaps
  --- @param menu_enable boolean|nil
  local function configure(user_keymaps, menu_enable)
    package.loaded["sandbox.config"] = nil
    local config = require("sandbox.config")
    config.options.keymaps = user_keymaps
    config.options.menu = menu_enable == nil and { enable = true } or { enable = menu_enable }
    config.options.refresh_interval = nil

    notices = {}
    package.loaded["sandbox.notify"] = {
      info = function(msg)
        notices[#notices + 1] = { level = "info", msg = msg }
      end,
      warn = function(msg)
        notices[#notices + 1] = { level = "warn", msg = msg }
      end,
      error = function(msg)
        notices[#notices + 1] = { level = "error", msg = msg }
      end,
    }

    cycled = 0
    package.loaded["sandbox.bindings.usrcmds.engine_commands"] = {
      cycle = function()
        cycled = cycled + 1
        return "podman"
      end,
    }
    package.loaded["sandbox.ui.list_actions"] = nil
    return require("sandbox.ui.list_actions")
  end

  after_each(function()
    for _, name in ipairs({
      "sandbox.config",
      "sandbox.notify",
      "sandbox.ui.list_actions",
      "sandbox.bindings.usrcmds.engine_commands",
      "sandbox.integrations.menu",
      "ui.kit",
    }) do
      package.loaded[name] = nil
    end
    vim.cmd("silent! %bwipeout!")
  end)

  --- @param list_actions table
  --- @param bufnr integer
  --- @param calls table
  --- @param opts table|nil
  local function bind_two_actions(list_actions, bufnr, calls, opts)
    list_actions.set_keymaps(bufnr, {
      {
        lhs = "<CR>",
        desc = "inspect",
        fn = function(item)
          calls[#calls + 1] = { action = "inspect", item = item }
        end,
      },
      {
        lhs = "i",
        desc = "inspect",
        fn = function(item)
          calls[#calls + 1] = { action = "inspect", item = item }
        end,
      },
      {
        lhs = "D",
        desc = "remove",
        fn = function(item)
          calls[#calls + 1] = { action = "remove", item = item }
        end,
      },
      {
        lhs = "L",
        desc = "logs (follow)",
        fn = function(item)
          calls[#calls + 1] = { action = "logs_follow", item = item }
        end,
      },
      {
        lhs = "R",
        desc = "refresh list",
        no_item = true,
        fn = function()
          calls[#calls + 1] = { action = "refresh" }
        end,
      },
    }, { { name = "one" }, { name = "two" } }, 0, opts)
  end

  it("binds every declared key plus the four shared ones", function()
    local list_actions = configure(nil)
    local bufnr = buffer_with({ "one", "two" })
    bind_two_actions(list_actions, bufnr, {}, { surface = "containers", filter = function() end })

    local maps = keymaps_of(bufnr, "n")
    for _, lhs in ipairs({ "<CR>", "i", "D", "L", "R", "q", "E", "f", "?" }) do
      assert.is_not_nil(maps[lhs], "no mapping for " .. lhs)
    end
  end)

  it("offers the filter key only to a view that declared a filter", function()
    local list_actions = configure(nil)
    local bufnr = buffer_with({ "one", "two" })
    bind_two_actions(list_actions, bufnr, {}, { surface = "containers" })

    assert.is_nil(keymaps_of(bufnr, "n")["f"])
  end)

  it("hands the item under the cursor to the action", function()
    local list_actions = configure(nil)
    local calls = {}
    local bufnr = buffer_with({ "one", "two" })
    bind_two_actions(list_actions, bufnr, calls, { surface = "containers" })

    vim.api.nvim_win_set_cursor(0, { 2, 0 })
    press("D")

    assert.are.equal("remove", calls[1].action)
    assert.are.equal("two", calls[1].item.name)
  end)

  it("says so rather than acting when the cursor is on no item", function()
    local list_actions = configure(nil)
    local calls = {}
    local bufnr = buffer_with({ "one", "two", "", "trailing" })
    bind_two_actions(list_actions, bufnr, calls, { surface = "containers" })

    vim.api.nvim_win_set_cursor(0, { 4, 0 })
    press("D")

    assert.are.same({}, calls)
    assert.are.equal("No item on this line", notices[#notices].msg)
  end)

  it("runs a no_item action wherever the cursor is", function()
    local list_actions = configure(nil)
    local calls = {}
    local bufnr = buffer_with({ "one", "two", "", "trailing" })
    bind_two_actions(list_actions, bufnr, calls, { surface = "containers" })

    vim.api.nvim_win_set_cursor(0, { 4, 0 })
    press("R")

    assert.are.equal("refresh", calls[1].action)
  end)

  describe("the user's keymaps spec", function()
    it("moves one action by its slugified name", function()
      -- "logs (follow)" is the action `logs_follow`; that name is the public
      -- contract of this module, so it is asserted rather than assumed.
      local list_actions = configure({ containers = { logs_follow = "gl" } })
      local bufnr = buffer_with({ "one", "two" })
      bind_two_actions(list_actions, bufnr, {}, { surface = "containers" })

      local maps = keymaps_of(bufnr, "n")
      assert.is_not_nil(maps["gl"])
      assert.is_nil(maps["L"])
    end)

    it("drops one action with false", function()
      local list_actions = configure({ containers = { remove = false } })
      local bufnr = buffer_with({ "one", "two" })
      bind_two_actions(list_actions, bufnr, {}, { surface = "containers" })

      assert.is_nil(keymaps_of(bufnr, "n")["D"])
      assert.is_not_nil(keymaps_of(bufnr, "n")["i"])
    end)

    it("binds no key action at all for keymaps = false", function()
      local list_actions = configure(false)
      local bufnr = buffer_with({ "one", "two" })
      bind_two_actions(list_actions, bufnr, {}, { surface = "containers", filter = function() end })

      local maps = keymaps_of(bufnr, "n")
      for _, lhs in ipairs({ "<CR>", "i", "D", "L", "R", "q", "E", "f", "?" }) do
        assert.is_nil(maps[lhs], lhs .. " was bound although keymaps = false")
      end
    end)

    it("BUG: keymaps = false still binds <RightMouse>, and the menu it opens is empty", function()
      -- `keymaps = false` is documented as "binds none" (config/DEFAULTS.lua),
      -- and it does switch off all thirteen key actions -- but the context-menu
      -- trigger is gated on `config.menu.enable` alone, so `<RightMouse>` is
      -- still claimed on every list buffer. What it then offers is built from
      -- `resolved_keys`, which is empty precisely because nothing was bound:
      -- the user who asked for no mappings gets one mapping, and it opens an
      -- empty menu.
      --
      -- Pinned rather than fixed: which of the two settings should win is a
      -- decision, not an oversight to correct silently. Either gate the
      -- trigger on `keymaps ~= false` too, or skip the binding when
      -- `resolved_keys` comes back empty.
      local captured
      package.loaded["sandbox.integrations.menu"] = {
        items = function(keys, item)
          captured = { keys = keys, item = item }
          return {}
        end,
      }
      local list_actions = configure(false)
      local bufnr = buffer_with({ "one", "two" })
      bind_two_actions(list_actions, bufnr, {}, { surface = "containers", filter = function() end })

      assert.is_not_nil(keymaps_of(bufnr, "n")["<RightMouse>"])

      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      press("<RightMouse>")

      assert.is_not_nil(captured, "the menu provider was never asked")
      assert.are.same({}, captured.keys)
    end)

    it("drops one whole surface with keymaps.<kind> = false", function()
      local list_actions = configure({ containers = false })
      local bufnr = buffer_with({ "one", "two" })
      bind_two_actions(list_actions, bufnr, {}, { surface = "containers" })

      local maps = keymaps_of(bufnr, "n")
      assert.is_nil(maps["D"])
      assert.is_nil(maps["i"])
      -- The shared four live under `keymaps.list`, so they survive.
      assert.is_not_nil(maps["q"])
    end)

    it("moves a shared key through keymaps.list, not through the kind", function()
      local list_actions = configure({ list = { close = "<Esc>" } })
      local bufnr = buffer_with({ "one", "two" })
      bind_two_actions(list_actions, bufnr, {}, { surface = "containers" })

      local maps = keymaps_of(bufnr, "n")
      assert.is_not_nil(maps["<Esc>"])
      assert.is_nil(maps["q"])
    end)

    it("ignores a spec that is neither a table nor false", function()
      local list_actions = configure("nonsense")
      local bufnr = buffer_with({ "one", "two" })
      bind_two_actions(list_actions, bufnr, {}, { surface = "containers" })

      assert.is_not_nil(keymaps_of(bufnr, "n")["D"])
    end)
  end)

  it("`q` closes the list buffer", function()
    local list_actions = configure(nil)
    local bufnr = buffer_with({ "one", "two" })
    bind_two_actions(list_actions, bufnr, {}, { surface = "containers" })

    press("q")

    assert.is_false(vim.api.nvim_buf_is_valid(bufnr))
  end)

  it("`E` cycles the engine and re-renders when the view knows how", function()
    local list_actions = configure(nil)
    local refreshed = 0
    local bufnr = buffer_with({ "one", "two" })
    bind_two_actions(list_actions, bufnr, {}, {
      surface = "containers",
      refresh = function()
        refreshed = refreshed + 1
      end,
    })

    press("E")

    assert.are.equal(1, cycled)
    assert.are.equal(1, refreshed)
  end)

  it("`E` still switches when the view cannot re-render itself", function()
    local list_actions = configure(nil)
    local bufnr = buffer_with({ "one", "two" })
    bind_two_actions(list_actions, bufnr, {}, { surface = "containers" })

    press("E")

    assert.are.equal(1, cycled)
  end)

  it("`?` lists the keys that are really bound, not the declared defaults", function()
    local list_actions = configure({ containers = { logs_follow = "gl", remove = false } })
    local bufnr = buffer_with({ "one", "two" })
    bind_two_actions(list_actions, bufnr, {}, { surface = "containers" })

    press("?")

    local help = notices[#notices].msg
    assert.is_truthy(help:find("gl", 1, true), help)
    assert.is_truthy(help:find("logs (follow)", 1, true), help)
    assert.is_falsy(help:find("remove", 1, true), help)
    -- the shared keys are listed too
    assert.is_truthy(help:find("close list buffer", 1, true), help)
  end)

  it("`f` asks for a query and hands it to the view, trimmed", function()
    local list_actions = configure(nil)
    local queries = {}
    local bufnr = buffer_with({ "one", "two" })
    package.loaded["ui.kit"] = setmetatable({
      input = function(opts)
        opts.on_submit("  web  ")
      end,
    }, { __index = require("ui.kit") })
    bind_two_actions(list_actions, bufnr, {}, {
      surface = "containers",
      filter = function(query)
        queries[#queries + 1] = query
      end,
    })

    press("f")

    assert.are.same({ "web" }, queries)
  end)

  it("treats a cancelled filter prompt as an empty query", function()
    local list_actions = configure(nil)
    local queries = {}
    local bufnr = buffer_with({ "one", "two" })
    package.loaded["ui.kit"] = setmetatable({
      input = function(opts)
        opts.on_submit(nil)
      end,
    }, { __index = require("ui.kit") })
    bind_two_actions(list_actions, bufnr, {}, {
      surface = "containers",
      filter = function(query)
        queries[#queries + 1] = query
      end,
    })

    press("f")

    assert.are.same({ "" }, queries)
  end)

  describe("the right-click menu", function()
    it("mirrors the keys that are actually bound", function()
      local captured
      package.loaded["sandbox.integrations.menu"] = {
        items = function(keys, item)
          captured = { keys = keys, item = item }
          return {}
        end,
      }
      local list_actions = configure({ containers = { remove = false } })
      local bufnr = buffer_with({ "one", "two" })
      bind_two_actions(list_actions, bufnr, {}, { surface = "containers" })

      -- The binding is a <RightMouse> keymap on the buffer; invoking the
      -- provider directly is what the menu does when it opens.
      local maps = keymaps_of(bufnr, "n")
      assert.is_not_nil(maps["<RightMouse>"], vim.inspect(maps))

      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      press("<RightMouse>")

      assert.is_not_nil(captured, "the menu provider was never asked")
      local descs = {}
      for _, k in ipairs(captured.keys) do
        descs[k.desc] = true
      end
      assert.is_nil(descs["remove"], "an unbound action was still offered in the menu")
      assert.is_truthy(descs["inspect"])
    end)

    it("is not bound at all when the menu is switched off", function()
      local list_actions = configure(nil, false)
      local bufnr = buffer_with({ "one", "two" })
      bind_two_actions(list_actions, bufnr, {}, { surface = "containers" })

      assert.is_nil(keymaps_of(bufnr, "n")["<RightMouse>"])
    end)
  end)
end)

describe("ui.list_actions.bind_close", function()
  after_each(function()
    package.loaded["sandbox.config"] = nil
    vim.cmd("silent! %bwipeout!")
  end)

  it("binds q and deletes the buffer", function()
    local bufnr = buffer_with({ "log line" })
    require("sandbox.ui.list_actions").bind_close(bufnr, "logs", "stop following logs")

    press("q")

    assert.is_false(vim.api.nvim_buf_is_valid(bufnr))
  end)

  it("runs the `before` hook first, so a stream is stopped before its buffer goes", function()
    local order = {}
    local bufnr = buffer_with({ "log line" })
    require("sandbox.ui.list_actions").bind_close(bufnr, "logs", "stop", function()
      order[#order + 1] = vim.api.nvim_buf_is_valid(bufnr) and "buffer-still-there" or "buffer-gone"
    end)

    press("q")

    assert.are.same({ "buffer-still-there" }, order)
    assert.is_false(vim.api.nvim_buf_is_valid(bufnr))
  end)

  it("can be moved through keymaps.<surface>.close", function()
    package.loaded["sandbox.config"] = nil
    require("sandbox.config").options.keymaps = { logs = { close = "x" } }
    local bufnr = buffer_with({ "log line" })
    require("sandbox.ui.list_actions").bind_close(bufnr, "logs", "stop")

    local maps = {}
    for _, map in ipairs(vim.api.nvim_buf_get_keymap(bufnr, "n")) do
      maps[map.lhs] = true
    end
    assert.is_true(maps["x"])
    assert.is_nil(maps["q"])
  end)
end)

describe("ui.list_actions.bulk_confirm_then", function()
  local asked

  before_each(function()
    asked = {}
    package.loaded["sandbox.util.confirm"] = {
      destructive = function(question, on_confirm)
        asked[#asked + 1] = question
        on_confirm()
      end,
    }
    package.loaded["sandbox.config"] = nil
  end)

  after_each(function()
    package.loaded["sandbox.util.confirm"] = nil
    package.loaded["sandbox.config"] = nil
  end)

  local function ref(item)
    return item.name
  end

  it("names every item it is about to act on", function()
    local removed = {}
    require("sandbox.ui.list_actions").bulk_confirm_then(
      "Remove",
      "container",
      { { name = "web" }, { name = "db" } },
      ref,
      function(id)
        removed[#removed + 1] = id
      end
    )

    assert.are.equal(1, #asked)
    assert.is_truthy(asked[1]:find("Remove 2 containers?", 1, true), asked[1])
    assert.is_truthy(asked[1]:find("  web", 1, true))
    assert.is_truthy(asked[1]:find("  db", 1, true))
    assert.are.same({ "web", "db" }, removed)
  end)

  it("keeps the noun singular for one item", function()
    require("sandbox.ui.list_actions").bulk_confirm_then("Kill", "container", { { name = "web" } }, ref, function() end)

    assert.is_truthy(asked[1]:find("Kill 1 container?", 1, true), asked[1])
  end)

  it("caps the list at ten and says how many more there are", function()
    local items = {}
    for i = 1, 14 do
      items[i] = { name = "c" .. i }
    end

    require("sandbox.ui.list_actions").bulk_confirm_then("Remove", "container", items, ref, function() end)

    assert.is_truthy(asked[1]:find("… and 4 more", 1, true), asked[1])
    assert.is_falsy(asked[1]:find("c11", 1, true))
  end)
end)

describe("ui.list_actions.setup_autorefresh", function()
  --- @param interval integer|nil
  local function configure(interval)
    package.loaded["sandbox.config"] = nil
    require("sandbox.config").options.refresh_interval = interval
    package.loaded["sandbox.ui.list_actions"] = nil
    return require("sandbox.ui.list_actions")
  end

  after_each(function()
    package.loaded["sandbox.config"] = nil
    package.loaded["sandbox.ui.list_actions"] = nil
    vim.cmd("silent! %bwipeout!")
  end)

  it("arms no timer when the interval is nil or zero", function()
    for _, interval in ipairs({ 0, -1 }) do
      local list_actions = configure(interval)
      local bufnr = buffer_with({ "one" })
      local refreshed = 0

      list_actions.setup_autorefresh(bufnr, function()
        refreshed = refreshed + 1
      end)
      vim.wait(60)

      assert.are.equal(0, refreshed, "interval " .. interval)
      assert.is_nil(vim.b[bufnr].sandbox_autorefresh_active)
    end

    local list_actions = configure(nil)
    local bufnr = buffer_with({ "one" })
    list_actions.setup_autorefresh(bufnr, function() end)
    assert.is_nil(vim.b[bufnr].sandbox_autorefresh_active)
  end)

  -- ERR-22: an invalid single config value degrades to its default (nil,
  -- i.e. disabled) instead of raising out of the numeric comparison and
  -- taking the rest of the view's own rendering down with it.
  it("degrades to disabled instead of raising when refresh_interval is not a number", function()
    local list_actions = configure("2000")
    local bufnr = buffer_with({ "one" })

    assert.has_no.errors(function()
      list_actions.setup_autorefresh(bufnr, function() end)
    end)
    assert.is_nil(vim.b[bufnr].sandbox_autorefresh_active)
  end)

  it("re-runs the refresh while the buffer is on screen", function()
    local list_actions = configure(20)
    local bufnr = buffer_with({ "one" })
    local refreshed = 0

    list_actions.setup_autorefresh(bufnr, function()
      refreshed = refreshed + 1
    end)
    vim.wait(400, function()
      return refreshed >= 2
    end)

    assert.is_true(refreshed >= 2, "refreshed " .. refreshed .. " times")
    assert.is_true(vim.b[bufnr].sandbox_autorefresh_active)
  end)

  it("arms only one timer however often the view re-renders", function()
    local list_actions = configure(20)
    local bufnr = buffer_with({ "one" })
    local first, second = 0, 0

    list_actions.setup_autorefresh(bufnr, function()
      first = first + 1
    end)
    list_actions.setup_autorefresh(bufnr, function()
      second = second + 1
    end)
    vim.wait(200, function()
      return first >= 2
    end)

    assert.is_true(first >= 1)
    assert.are.equal(0, second, "a second timer was armed for the same buffer")
  end)

  it("stops refreshing once the buffer is no longer in a window", function()
    local list_actions = configure(20)
    local bufnr = buffer_with({ "one" })
    local refreshed = 0

    list_actions.setup_autorefresh(bufnr, function()
      refreshed = refreshed + 1
    end)
    vim.wait(200, function()
      return refreshed >= 1
    end)

    vim.api.nvim_win_close(vim.fn.bufwinid(bufnr), true)
    local seen = refreshed
    vim.wait(200)

    assert.are.equal(seen, refreshed, "the timer kept running after the window closed")
  end)

  it("survives its buffer being wiped -- the timer is closed, not left dangling", function()
    local list_actions = configure(20)
    local bufnr = buffer_with({ "one" })
    local refreshed = 0

    list_actions.setup_autorefresh(bufnr, function()
      refreshed = refreshed + 1
    end)
    vim.wait(60)

    assert.has_no.errors(function()
      vim.api.nvim_buf_delete(bufnr, { force = true })
      vim.wait(120)
    end)
  end)
end)
