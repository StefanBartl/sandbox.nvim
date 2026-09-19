-- The five list views: what they render, and -- the part that silently breaks
-- -- whether the key on a given screen line acts on the item that is actually
-- on that line.
--
-- Three of the views print a two-line header and pass `header_offset = 2`;
-- two print none and pass 0. Get that pair out of step and every key acts on
-- the wrong container: not an error, not a crash, just the wrong `docker rm`.
-- So each view is rendered with distinguishable items, the cursor is put on a
-- known row, and the key is pressed for real through `nvim_feedkeys`.
--
-- The command modules are recorders, so no key ever reaches an engine.
---@diagnostic disable: need-check-nil

--- @return table log
local function stub_command_modules()
  local log = {}
  for _, module in ipairs({ "container_commands", "volume_commands", "network_commands", "image_commands" }) do
    local name = module
    local stub = {}
    for _, fn in ipairs({
      "list",
      "inspect",
      "logs",
      "logs_follow",
      "exec",
      "start",
      "stop",
      "kill",
      "restart",
      "pause",
      "unpause",
      "rename",
      "remove",
      "prune",
      "stats",
      "top",
      "create",
      "connect",
      "disconnect",
      "pull",
      "push",
      "tag",
      "save",
      "load",
      "history",
    }) do
      stub[fn] = function(...)
        log[#log + 1] = { module = name, fn = fn, args = { ... } }
      end
    end
    package.loaded["sandbox.bindings.usrcmds." .. name] = stub
  end
  return log
end

--- @return table notices
local function stub_notify()
  local notices = {}
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
  return notices
end

local function cleanup()
  for _, name in ipairs({
    "sandbox.notify",
    "sandbox.config",
    "sandbox.bindings.usrcmds.container_commands",
    "sandbox.bindings.usrcmds.volume_commands",
    "sandbox.bindings.usrcmds.network_commands",
    "sandbox.bindings.usrcmds.image_commands",
    "sandbox.bindings.usrcmds.engine_commands",
    "sandbox.ui.list_view",
    "sandbox.ui.volume_list_view",
    "sandbox.ui.network_list_view",
    "sandbox.ui.image_list_view_docker",
    "sandbox.ui.image_list_view_podman",
    "sandbox.ui.list_actions",
  }) do
    package.loaded[name] = nil
  end
  vim.cmd("silent! %bwipeout!")
end

--- Press `keys` in the current window, for real.
--- @param keys string
local function press(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "x", false)
end

--- @param bufnr integer
--- @return string[]
local function lines_of(bufnr)
  return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
end

describe("ui list views", function()
  local log

  before_each(function()
    cleanup()
    log = stub_command_modules()
    stub_notify()
  end)

  after_each(cleanup)

  --- One case per view: how to render it, what the items are, how many header
  --- lines it prints, and which command module its keys must reach.
  local VIEWS = {
    {
      name = "list_view (containers)",
      module = "sandbox.ui.list_view",
      buffer = "sandbox.nvim://container-list",
      header = 0,
      items = {
        { id = "aaaaaaaaaaaabbbb", name = "web", status = "running", image = "nginx" },
        { id = "ccccccccccccdddd", name = "db", status = "exited", image = "postgres" },
      },
      command_module = "container_commands",
      refs = { "aaaaaaaaaaaabbbb", "ccccccccccccdddd" },
    },
    {
      name = "volume_list_view",
      module = "sandbox.ui.volume_list_view",
      buffer = "sandbox.nvim://volume-list",
      header = 2,
      items = {
        { name = "data", driver = "local", mountpoint = "/var/lib/data" },
        { name = "cache", driver = "local", mountpoint = "/var/lib/cache" },
      },
      command_module = "volume_commands",
      refs = { "data", "cache" },
    },
    {
      name = "network_list_view",
      module = "sandbox.ui.network_list_view",
      buffer = "sandbox.nvim://network-list",
      header = 2,
      items = {
        { id = "n1", name = "bridge", driver = "bridge", scope = "local" },
        { id = "n2", name = "host", driver = "host", scope = "local" },
      },
      command_module = "network_commands",
      refs = { "bridge", "host" },
    },
    {
      name = "image_list_view_docker",
      module = "sandbox.ui.image_list_view_docker",
      buffer = "sandbox.nvim://image-list",
      header = 0,
      items = {
        { id = "i1", repository = "nginx", tag = "latest", size = "142MB" },
        { id = "i2", repository = "alpine", tag = "3.20", size = "7.8MB" },
      },
      command_module = "image_commands",
      refs = { "nginx:latest", "alpine:3.20" },
    },
    {
      name = "image_list_view_podman",
      module = "sandbox.ui.image_list_view_podman",
      buffer = "sandbox.nvim://images",
      header = 2,
      items = {
        { Id = "i1", Names = { "docker.io/library/nginx:latest" }, Size = 142000000 },
        { Id = "i2", Names = { "quay.io/podman/stable:v5" }, Size = 7800000 },
      },
      command_module = "image_commands",
      refs = { "docker.io/library/nginx:latest", "quay.io/podman/stable:v5" },
    },
  }

  for _, view in ipairs(VIEWS) do
    describe(view.name, function()
      it("renders one line per item under its header", function()
        local render = require(view.module)
        render(view.items)

        local bufnr = vim.api.nvim_get_current_buf()
        assert.are.equal(view.buffer, vim.api.nvim_buf_get_name(bufnr))
        assert.are.equal(view.header + #view.items, #lines_of(bufnr))
      end)

      it("acts on the item under the cursor, not on the line number", function()
        local render = require(view.module)
        render(view.items)

        local bufnr = vim.api.nvim_get_current_buf()
        for i, ref in ipairs(view.refs) do
          log[#log] = nil
          vim.api.nvim_win_set_cursor(0, { view.header + i, 0 })
          press("i")

          local call = log[#log]
          assert.is_not_nil(call, view.name .. ": row " .. i .. " did nothing")
          assert.are.equal(view.command_module, call.module)
          assert.are.equal("inspect", call.fn)
          assert.are.equal(ref, call.args[1], view.name .. ": row " .. i .. " named the wrong item")
        end
        assert.are.equal(bufnr, vim.api.nvim_get_current_buf())
      end)

      if view.header > 0 then
        it("says so instead of acting when the cursor is on the header", function()
          local notices = stub_notify()
          local render = require(view.module)
          render(view.items)

          vim.api.nvim_win_set_cursor(0, { 1, 0 })
          press("i")

          assert.are.equal(0, #log, view.name .. ": the header row acted on an item")
          assert.are.equal("No item on this line", notices[#notices].msg)
        end)
      end

      it("refreshes without needing an item under the cursor", function()
        local render = require(view.module)
        render(view.items)

        vim.api.nvim_win_set_cursor(0, { 1, 0 })
        press("R")

        local call = log[#log]
        assert.are.equal("list", call.fn)
        assert.are.equal(view.command_module, call.module)
      end)
    end)
  end

  it("the container list prints status, name and a shortened id", function()
    require("sandbox.ui.list_view")({
      { id = "0123456789abcdef0123", name = "web", status = "running" },
    })

    assert.are.same({ "[running] web (0123456789ab)" }, lines_of(vim.api.nvim_get_current_buf()))
  end)

  it("the container list fills in placeholders for whatever the engine omitted", function()
    require("sandbox.ui.list_view")({ {} })

    assert.are.same({ "[unknown] <no name> (<no id>)" }, lines_of(vim.api.nvim_get_current_buf()))
  end)

  it("the container list highlights each status by what it means", function()
    local ns = vim.api.nvim_create_namespace("sandbox_container_status")
    require("sandbox.ui.list_view")({
      { id = "a", name = "up", status = "running" },
      { id = "b", name = "down", status = "exited" },
      { id = "c", name = "held", status = "paused" },
      { id = "d", name = "odd", status = "created" },
    })

    local bufnr = vim.api.nvim_get_current_buf()
    local marks = vim.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, { details = true })
    assert.are.equal(4, #marks)
    local groups = {}
    for _, mark in ipairs(marks) do
      groups[#groups + 1] = mark[4].hl_group
    end
    assert.are.same({
      "SandboxStatusRunning",
      "SandboxStatusStopped",
      "SandboxStatusPaused",
      "SandboxStatusOther",
    }, groups)
  end)

  -- ERR-02: `vim.hl` only exists from Neovim 0.11 (the rename of
  -- `vim.highlight`), while README.md/installation.md advertise 0.10+. On
  -- the documented minimum, indexing a nil `vim.hl` throws inside the
  -- render loop -- pinned here by simulating that Neovim with `vim.hl = nil`
  -- rather than by actually running an old Neovim.
  it("falls back to vim.highlight.range when vim.hl is absent (pre-0.11)", function()
    local saved_hl = vim.hl
    vim.hl = nil

    local ok = pcall(function()
      local ns = vim.api.nvim_create_namespace("sandbox_container_status")
      require("sandbox.ui.list_view")({
        { id = "a", name = "up", status = "running" },
      })

      local bufnr = vim.api.nvim_get_current_buf()
      local marks = vim.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, { details = true })
      assert.are.equal(1, #marks)
      assert.are.equal("SandboxStatusRunning", marks[1][4].hl_group)
    end)

    vim.hl = saved_hl
    assert.is_true(ok, "must not throw with vim.hl absent")
  end)

  it("the podman image view formats sizes and splits repo:tag at the last colon", function()
    require("sandbox.ui.image_list_view_podman")({
      { Id = "abcdef123456789", Names = { "registry.example.com:5000/team/app:1.0" }, Size = 1536 },
    })

    local rendered = lines_of(vim.api.nvim_get_current_buf())[3]
    assert.is_truthy(rendered:find("registry.example.com:5000/team/app", 1, true), rendered)
    assert.is_truthy(rendered:find("1.0", 1, true), rendered)
    assert.is_truthy(rendered:find("abcdef123456", 1, true), rendered)
    assert.is_truthy(rendered:find("1.5 KB", 1, true), rendered)
  end)

  it("the podman image view survives an image with no Names at all", function()
    require("sandbox.ui.image_list_view_podman")({ { Id = "abc", Size = 0 } })

    local rendered = lines_of(vim.api.nvim_get_current_buf())[3]
    assert.is_truthy(rendered:find("<none>", 1, true), rendered)
  end)

  -- LUA-16: `podman images --format json` marshals a nil Names slice as JSON
  -- `null`, which vim.fn.json_decode turns into vim.NIL -- truthy userdata
  -- that an `or {}`/`or "<none>..."` default does not catch, unlike Lua nil.
  it("the podman image view survives an image whose Names/Id decoded to vim.NIL", function()
    require("sandbox.ui.image_list_view_podman")({ { Id = vim.NIL, Names = vim.NIL, Size = 0 } })

    local rendered = lines_of(vim.api.nvim_get_current_buf())[3]
    assert.is_truthy(rendered:find("<none>", 1, true), rendered)
  end)

  describe("a list that is not a list", function()
    local GUARDED = {
      { name = "list_view", module = "sandbox.ui.list_view", says = "Invalid container list" },
      { name = "volume_list_view", module = "sandbox.ui.volume_list_view", says = "Invalid volume list" },
      { name = "network_list_view", module = "sandbox.ui.network_list_view", says = "Invalid network list" },
      { name = "image_list_view_docker", module = "sandbox.ui.image_list_view_docker", says = "Invalid image list" },
    }

    for _, case in ipairs(GUARDED) do
      it(case.name .. " reports it rather than rendering nothing", function()
        local notices = stub_notify()

        require(case.module)("not a list")

        assert.are.equal("error", notices[1].level)
        assert.is_truthy(notices[1].msg:find(case.says, 1, true))
      end)
    end

    it("image_list_view_podman has no such guard and raises instead (asymmetry, not reachable today)", function()
      -- Its four siblings all check `type(x) ~= "table"` first. This one does
      -- not, so a caller that hands it a string gets
      -- `bad argument #1 to 'ipairs'` out of the view. Reachable today only
      -- through the same `image_commands.list` path that guards the value
      -- before the call, which is why it is pinned rather than fixed: the fix
      -- is a copy of the guard from the docker view, and adding it changes
      -- what the view reports.
      stub_notify()

      assert.has_errors(function()
        require("sandbox.ui.image_list_view_podman")("not a list")
      end)
    end)
  end)
end)

describe("ui list_view filtering", function()
  before_each(function()
    cleanup()
    stub_command_modules()
    stub_notify()
  end)

  after_each(cleanup)

  local ITEMS = {
    { id = "aaa", name = "web", status = "running", image = "nginx" },
    { id = "bbb", name = "worker", status = "exited", image = "python" },
    { id = "ccc", name = "db", status = "running", image = "postgres" },
  }

  --- Drive the `f` key with a canned answer, through a faked ui.kit.input.
  --- @param answer string
  local function filter_with(answer)
    package.loaded["ui.kit"] = setmetatable({
      input = function(opts)
        opts.on_submit(answer)
      end,
    }, { __index = require("ui.kit") })
    press("f")
    package.loaded["ui.kit"] = nil
  end

  it("narrows across every field, not just the rendered text", function()
    require("sandbox.ui.list_view")(ITEMS)

    filter_with("postgres")

    -- The image name is not on the rendered line at all.
    assert.are.same({ "[running] db (ccc)" }, lines_of(vim.api.nvim_get_current_buf()))
  end)

  it("matches case-insensitively", function()
    require("sandbox.ui.list_view")(ITEMS)

    filter_with("WEB")

    assert.are.equal(1, #lines_of(vim.api.nvim_get_current_buf()))
  end)

  it("widens from the original list, so a second filter is not compounded onto the first", function()
    require("sandbox.ui.list_view")(ITEMS)

    filter_with("web")
    assert.are.equal(1, #lines_of(vim.api.nvim_get_current_buf()))

    -- "db" does not appear in the filtered list; it must still be found.
    filter_with("db")
    assert.are.same({ "[running] db (ccc)" }, lines_of(vim.api.nvim_get_current_buf()))
  end)

  it("restores the full list for an empty query", function()
    require("sandbox.ui.list_view")(ITEMS)

    filter_with("web")
    filter_with("")

    assert.are.equal(3, #lines_of(vim.api.nvim_get_current_buf()))
  end)

  it("keeps the list as it was and says so when nothing matches", function()
    local notices = stub_notify()
    require("sandbox.ui.list_view")(ITEMS)

    filter_with("nothing-like-this")

    assert.are.equal(3, #lines_of(vim.api.nvim_get_current_buf()))
    assert.is_truthy(notices[#notices].msg:find("No container matching", 1, true))
  end)

  it("offers no filter key on a view that cannot filter itself", function()
    require("sandbox.ui.volume_list_view")({ { name = "data" } })

    local maps = vim.api.nvim_buf_get_keymap(vim.api.nvim_get_current_buf(), "n")
    local has_f = false
    for _, map in ipairs(maps) do
      if map.lhs == "f" then
        has_f = true
      end
    end
    assert.is_false(has_f)
  end)
end)
