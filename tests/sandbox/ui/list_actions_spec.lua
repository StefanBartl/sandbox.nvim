--- Covers the multi-select (Visual-mode bulk action) machinery in
--- sandbox.ui.list_actions. This is exercised via real `nvim_feedkeys`
--- visual-mode key sequences rather than mocked marks/positions: an
--- earlier implementation read the `'<`/`'>` marks, which are only updated
--- once Visual mode is actually exited -- but a Lua-function keymap bound
--- in mode "x" runs its callback *while still in Visual mode*
--- (`mode()` still reports "v"/"V" at that point), so those marks are
--- stale/unset (0) when the callback runs. Only a real feedkeys sequence
--- would have caught that; a hand-built fake selection would not have.

local list_actions = require("sandbox.ui.list_actions")

local function make_buf(lines)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_open_win(bufnr, true, { relative = "editor", width = 30, height = 10, row = 0, col = 0 })
  return bufnr
end

describe("list_actions.set_visual_bulk_actions", function()
  local items = {
    { name = "a" },
    { name = "b" },
    { name = "c" },
  }

  it("captures a forward Visual-line selection (V, j, action)", function()
    local bufnr = make_buf({ "line1", "line2", "line3" })
    local captured
    list_actions.set_visual_bulk_actions(bufnr, {
      {
        lhs = "X",
        desc = "test",
        fn = function(selected)
          captured = selected
        end,
      },
    }, items, 0)

    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("VjX", true, false, true), "x", false)

    assert.are.same({ items[1], items[2] }, captured)
    assert.are.equal("n", vim.fn.mode())
  end)

  it("captures a backward Visual-line selection (cursor moving up)", function()
    local bufnr = make_buf({ "line1", "line2", "line3" })
    local captured
    list_actions.set_visual_bulk_actions(bufnr, {
      {
        lhs = "X",
        desc = "test",
        fn = function(selected)
          captured = selected
        end,
      },
    }, items, 0)

    vim.api.nvim_win_set_cursor(0, { 3, 0 })
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("VkkX", true, false, true), "x", false)

    assert.are.same({ items[1], items[2], items[3] }, captured)
  end)

  it("respects header_offset", function()
    local bufnr = make_buf({ "HEADER", "----", "line1", "line2" })
    local captured
    list_actions.set_visual_bulk_actions(bufnr, {
      {
        lhs = "X",
        desc = "test",
        fn = function(selected)
          captured = selected
        end,
      },
    }, items, 2)

    vim.api.nvim_win_set_cursor(0, { 3, 0 })
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("VjX", true, false, true), "x", false)

    assert.are.same({ items[1], items[2] }, captured)
  end)
end)

describe("list_actions.bulk_confirm_then", function()
  local orig_confirm_destructive

  before_each(function()
    package.loaded["sandbox.config"] = nil
    orig_confirm_destructive = require("sandbox.config").options.confirm_destructive
  end)

  after_each(function()
    require("sandbox.config").options.confirm_destructive = orig_confirm_destructive
    package.loaded["lib.nvim.ui.kit"] = nil
  end)

  it("prompts once for the whole batch, then restores confirm_destructive", function()
    require("sandbox.config").options.confirm_destructive = true

    local prompts = 0
    package.loaded["lib.nvim.ui.kit"] = {
      confirm = function(opts)
        prompts = prompts + 1
        opts.on_answer(true)
      end,
    }

    local applied = {}
    list_actions.bulk_confirm_then(
      "Remove",
      "widget",
      { { name = "a" }, { name = "b" }, { name = "c" } },
      function(item)
        return item.name
      end,
      function(id)
        applied[#applied + 1] = id
      end
    )

    assert.are.equal(1, prompts)
    assert.are.same({ "a", "b", "c" }, applied)
    assert.is_true(require("sandbox.config").options.confirm_destructive)
  end)

  it("skips the prompt entirely when confirm_destructive is false", function()
    require("sandbox.config").options.confirm_destructive = false

    local prompts = 0
    package.loaded["lib.nvim.ui.kit"] = {
      confirm = function(opts)
        prompts = prompts + 1
        opts.on_answer(true)
      end,
    }

    local applied = {}
    list_actions.bulk_confirm_then("Remove", "widget", { { name = "x" } }, function(i)
      return i.name
    end, function(id)
      applied[#applied + 1] = id
    end)

    assert.are.equal(0, prompts)
    assert.are.same({ "x" }, applied)
  end)
end)
