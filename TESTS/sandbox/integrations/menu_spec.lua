-- `integrations.menu` is the builder behind the right-click menu on every list
-- buffer. Built against the real `ui.contextmenu` (ui.nvim is a declared
-- dependency and is on the runtimepath here), so what is asserted is the item
-- shape that renderer really produces.
--
-- The rule worth pinning: the menu may never offer an action the keyboard does
-- not also offer at that spot. An entry whose action needs an item under the
-- cursor has to disappear when there is none -- otherwise right-clicking the
-- header row of a volume list would call `remove(nil)`.
---@diagnostic disable: need-check-nil

describe("sandbox.integrations.menu", function()
  local menu = require("sandbox.integrations.menu")

  --- @param calls table
  --- @return table keys
  local function keys(calls)
    return {
      {
        lhs = "<CR>",
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
        lhs = "R",
        desc = "refresh list",
        no_item = true,
        fn = function(...)
          calls[#calls + 1] = { action = "refresh", n = select("#", ...) }
        end,
      },
    }
  end

  it("mirrors every key one-to-one when the cursor is on an item", function()
    local items = menu.items(keys({}), { name = "web" })

    assert.are.equal(3, #items)
    assert.are.equal("  Inspect", items[1].name)
    assert.are.equal("<CR>", items[1].rtxt)
    assert.are.equal("  Remove", items[2].name)
    assert.are.equal("  Refresh list", items[3].name)
  end)

  it("capitalizes only the first letter, leaving the rest of the description alone", function()
    local items = menu.items({
      { lhs = "L", desc = "logs (follow)", fn = function() end },
    }, { name = "web" })

    assert.are.equal("  Logs (follow)", items[1].name)
  end)

  it("drops the item-dependent entries when there is nothing under the cursor", function()
    local items = menu.items(keys({}), nil)

    assert.are.equal(1, #items)
    assert.are.equal("  Refresh list", items[1].name)
  end)

  it("hands the item to the action it belongs to", function()
    local calls = {}
    local item = { name = "web" }
    local items = menu.items(keys(calls), item)

    items[2].cmd()

    assert.are.equal("remove", calls[1].action)
    assert.are.equal(item, calls[1].item)
  end)

  it("calls a no_item action with no arguments at all", function()
    local calls = {}
    local items = menu.items(keys(calls), nil)

    items[1].cmd()

    assert.are.equal("refresh", calls[1].action)
    assert.are.equal(0, calls[1].n)
  end)

  it("shows the first key as the hint when an action carries several", function()
    -- `list_actions` binds `<CR>` and `i` to one action; the hint takes the
    -- one the registry made the default.
    local items = menu.items({
      { lhs = { "<CR>", "i" }, desc = "inspect", fn = function() end },
    }, { name = "web" })

    assert.are.equal("<CR>", items[1].rtxt)
  end)

  it("returns an empty list for an empty key table, not nil", function()
    assert.are.same({}, menu.items({}, { name = "web" }))
    assert.are.same({}, menu.items({}, nil))
  end)

  describe("submenu", function()
    it("wraps the same entries as one nested item", function()
      local sub = menu.submenu("sandbox", keys({}), { name = "web" })

      assert.are.equal("sandbox", sub.name)
      assert.are.equal(3, #sub.items)
    end)

    it("is nil when there would be nothing to show", function()
      assert.is_nil(menu.submenu("sandbox", {}, nil))
    end)

    it("still offers the buffer-wide actions with no item under the cursor", function()
      local sub = menu.submenu("sandbox", keys({}), nil)

      assert.are.equal(1, #sub.items)
    end)
  end)
end)
