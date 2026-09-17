-- The four non-list views: the log snapshot, the error report, the inspect
-- tree, and the live log stream.
--
-- All four go through `lib.nvim.window.open_named_scratch`, which is real here
-- -- so these assert what ends up in the buffer, what its options are, and
-- (for the stream) that the process behind it is stopped on every way out of
-- the buffer. `follow_logs` is a double: it hands back a handle that records
-- whether it was stopped, which is the property that matters.
---@diagnostic disable: need-check-nil

local function cleanup()
  for _, name in ipairs({
    "sandbox.config",
    "sandbox.notify",
    "sandbox.ui.log_view",
    "sandbox.ui.error_view",
    "sandbox.ui.inspect_view",
    "sandbox.ui.log_follow_view",
    "sandbox.ui.list_actions",
  }) do
    package.loaded[name] = nil
  end
  vim.cmd("silent! %bwipeout!")
end

--- @param keys string
local function press(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "x", false)
end

--- @param bufnr integer
--- @return string[]
local function lines_of(bufnr)
  return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
end

--- @param name string
--- @return integer|nil
local function buffer_named(name)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_name(buf) == name then
      return buf
    end
  end
  return nil
end

describe("ui.log_view", function()
  after_each(cleanup)

  it("shows the lines in a buffer named after the container, read-only", function()
    require("sandbox.ui.log_view")({ "starting", "ready" }, "abc123")

    local bufnr = buffer_named("sandbox.nvim://logs/abc123")
    assert.is_not_nil(bufnr)
    assert.are.same({ "starting", "ready" }, lines_of(bufnr))
    assert.is_false(vim.bo[bufnr].modifiable)
    assert.are.equal("log", vim.bo[bufnr].filetype)
  end)

  it("reuses the same buffer for the same key instead of stacking them up", function()
    require("sandbox.ui.log_view")({ "first" }, "abc123")
    require("sandbox.ui.log_view")({ "second" }, "abc123")

    local count = 0
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_get_name(buf) == "sandbox.nvim://logs/abc123" then
        count = count + 1
      end
    end
    assert.are.equal(1, count)
    assert.are.same({ "second" }, lines_of(buffer_named("sandbox.nvim://logs/abc123")))
  end)

  it("keeps stats and top apart, since both come through here", function()
    require("sandbox.ui.log_view")({ "cpu" }, "stats/abc123")
    require("sandbox.ui.log_view")({ "pid" }, "top/abc123")

    assert.is_not_nil(buffer_named("sandbox.nvim://logs/stats/abc123"))
    assert.is_not_nil(buffer_named("sandbox.nvim://logs/top/abc123"))
  end)
end)

describe("ui.error_view", function()
  after_each(cleanup)

  it("opens one named buffer with the error lines", function()
    require("sandbox.ui.error_view")({ "Failed to list containers:", "daemon not reachable" })

    local bufnr = buffer_named("sandbox.nvim://error-view")
    assert.is_not_nil(bufnr)
    assert.are.same({ "Failed to list containers:", "daemon not reachable" }, lines_of(bufnr))
  end)

  it("replaces its content rather than opening a second report", function()
    require("sandbox.ui.error_view")({ "first failure" })
    require("sandbox.ui.error_view")({ "second failure" })

    assert.are.same({ "second failure" }, lines_of(buffer_named("sandbox.nvim://error-view")))
  end)
end)

describe("ui.inspect_view", function()
  after_each(cleanup)

  it("renders a table as an inspectable, foldable Lua view", function()
    require("sandbox.ui.inspect_view")({ Id = "abc123", State = { Running = true } }, "abc123")

    local bufnr = buffer_named("sandbox.nvim://inspect/abc123")
    assert.is_not_nil(bufnr)
    local text = table.concat(lines_of(bufnr), "\n")
    assert.is_truthy(text:find("Id", 1, true))
    assert.is_truthy(text:find("Running", 1, true))
    assert.are.equal("lua", vim.bo[bufnr].filetype)

    local winid = vim.fn.bufwinid(bufnr)
    assert.are.equal("indent", vim.wo[winid].foldmethod)
    assert.are.equal(1, vim.wo[winid].foldlevel)
  end)

  it("BUG: an error list is vim.inspect()ed too, so the message arrives unreadable", function()
    -- The view's own signature is `@param data table | string[]` and its body
    -- reads:
    --
    --     if type(data) == "table" then ... vim.inspect(data) ...
    --     else lines = data -- already an error string[] end
    --
    -- A `string[]` *is* a table, so the second branch cannot be reached and
    -- the comment describes dead code. Every inspect failure goes down the
    -- first branch instead: the adapters report one by returning
    -- `{ "[sandbox.nvim] Error inspecting container:\n<raw CLI text>" }`, and
    -- what the user gets is that list rendered as Lua source -- one line, with
    -- the newline shown as a literal `\n` and the whole message in quotes.
    -- Exactly the moment the raw text matters is the moment it is hardest to
    -- read, and a multi-line daemon error is unreadable.
    --
    -- Pinned rather than fixed: the fix (`vim.islist(data)` -- or checking for
    -- a string first element -- before inspecting) changes what every inspect
    -- failure looks like, which is a visible behaviour change.
    require("sandbox.ui.inspect_view")({ "[sandbox.nvim] Error inspecting container:\nno such object" }, "abc123")

    local rendered = lines_of(buffer_named("sandbox.nvim://inspect/abc123"))
    assert.are.equal(1, #rendered, "the error came out as more than one line -- has this been fixed?")
    assert.is_truthy(rendered[1]:find("^{ "), rendered[1])
    assert.is_truthy(rendered[1]:find("\\n", 1, true), "the newline should still be escaped: " .. rendered[1])
  end)

  it("binds q to close it", function()
    require("sandbox.ui.inspect_view")({ Id = "abc123" }, "abc123")
    local bufnr = buffer_named("sandbox.nvim://inspect/abc123")

    press("q")

    assert.is_false(vim.api.nvim_buf_is_valid(bufnr))
  end)
end)

describe("ui.log_follow_view", function()
  after_each(cleanup)

  --- A follow_logs double: records the stop, and lets the test push lines.
  --- @return table engine, table state
  local function fake_engine()
    local state = { stopped = 0 }
    local engine = {
      follow_logs = function(id, on_line, on_exit)
        state.id = id
        state.on_line = on_line
        state.on_exit = on_exit
        return {
          stop = function()
            state.stopped = state.stopped + 1
          end,
        }
      end,
    }
    return engine, state
  end

  it("opens a placeholder buffer and starts following", function()
    local engine, state = fake_engine()

    require("sandbox.ui.log_follow_view")(engine, "abc123")

    local bufnr = buffer_named("sandbox.nvim://logs/abc123")
    assert.is_not_nil(bufnr)
    assert.are.same({ "-- following logs, press q to stop --" }, lines_of(bufnr))
    assert.are.equal("abc123", state.id)
    assert.is_false(vim.bo[bufnr].modifiable)
  end)

  it("appends each streamed line and leaves the buffer read-only again", function()
    local engine, state = fake_engine()
    require("sandbox.ui.log_follow_view")(engine, "abc123")
    local bufnr = buffer_named("sandbox.nvim://logs/abc123")

    state.on_line("first")
    state.on_line("second")

    assert.are.same({ "-- following logs, press q to stop --", "first", "second" }, lines_of(bufnr))
    assert.is_false(vim.bo[bufnr].modifiable)
  end)

  it("follows the tail: the cursor moves to the last line", function()
    local engine, state = fake_engine()
    require("sandbox.ui.log_follow_view")(engine, "abc123")
    local bufnr = buffer_named("sandbox.nvim://logs/abc123")

    for i = 1, 5 do
      state.on_line("line " .. i)
    end

    local winid = vim.fn.bufwinid(bufnr)
    assert.are.equal(vim.api.nvim_buf_line_count(bufnr), vim.api.nvim_win_get_cursor(winid)[1])
  end)

  it("notes a non-zero exit in the buffer itself", function()
    local engine, state = fake_engine()
    require("sandbox.ui.log_follow_view")(engine, "abc123")
    local bufnr = buffer_named("sandbox.nvim://logs/abc123")

    state.on_exit(1)

    assert.are.equal("-- process exited (1) --", lines_of(bufnr)[2])
  end)

  it("says nothing about a clean exit", function()
    local engine, state = fake_engine()
    require("sandbox.ui.log_follow_view")(engine, "abc123")
    local bufnr = buffer_named("sandbox.nvim://logs/abc123")

    state.on_exit(0)
    state.on_exit(nil)

    assert.are.equal(1, #lines_of(bufnr))
  end)

  it("drops a line that arrives after the buffer is gone instead of raising", function()
    local engine, state = fake_engine()
    require("sandbox.ui.log_follow_view")(engine, "abc123")
    local bufnr = buffer_named("sandbox.nvim://logs/abc123")

    vim.api.nvim_buf_delete(bufnr, { force = true })

    assert.has_no.errors(function()
      state.on_line("too late")
    end)
  end)

  it("stops the process when q closes the buffer", function()
    local engine, state = fake_engine()
    require("sandbox.ui.log_follow_view")(engine, "abc123")
    local bufnr = buffer_named("sandbox.nvim://logs/abc123")

    press("q")

    assert.is_true(state.stopped >= 1, "the stream was left running")
    assert.is_false(vim.api.nvim_buf_is_valid(bufnr))
  end)

  it("stops the process when the buffer is wiped some other way", function()
    local engine, state = fake_engine()
    require("sandbox.ui.log_follow_view")(engine, "abc123")
    local bufnr = buffer_named("sandbox.nvim://logs/abc123")

    vim.api.nvim_buf_delete(bufnr, { force = true })

    assert.is_true(state.stopped >= 1, "wiping the buffer left the process running")
  end)
end)
