-- The command layer for containers, images, volumes and networks: the guard
-- that refuses an empty argument, the confirmation gate in front of every
-- destructive verb, which view gets the result, and what the user is told when
-- the engine says no.
--
-- Driven against a fake engine rather than fake use cases, so the real
-- `core.usecases.*` files are in the path -- they are one-line delegations and
-- this is where they get exercised end to end. The fake's convention: record
-- the call, then answer through a callback argument if there is one, and
-- return the same values if there is not, which is exactly the dual shape the
-- adapters have.
--
-- Two properties are worth stating up front, because they are easy to lose in
-- a refactor:
--   * the confirmation gate must sit *before* the use case, not around its
--     result -- a "no" may not reach the engine at all;
--   * an empty/missing id must not reach the engine either, or the CLI is
--     handed an empty positional and answers with its own error.
---@diagnostic disable: need-check-nil

--- @class CommandsHarness
--- @field notices table[]
--- @field calls table[]
--- @field views table[]
--- @field confirms string[]

--- @param opts { results?: table<string, any[]>, no_engine?: boolean, answer?: boolean|nil, skip_confirm?: boolean }
--- @return CommandsHarness
local function harness(opts)
  opts = opts or {}
  local H = { notices = {}, calls = {}, views = {}, confirms = {} }

  package.loaded["sandbox.notify"] = {
    info = function(msg, ctx)
      H.notices[#H.notices + 1] = { level = "info", msg = msg, ctx = ctx }
    end,
    warn = function(msg, ctx)
      H.notices[#H.notices + 1] = { level = "warn", msg = msg, ctx = ctx }
    end,
    error = function(msg, ctx)
      H.notices[#H.notices + 1] = { level = "error", msg = msg, ctx = ctx }
    end,
  }

  package.loaded["sandbox.util.confirm"] = {
    destructive = function(prompt, on_confirm)
      H.confirms[#H.confirms + 1] = prompt
      if opts.skip_confirm or opts.answer ~= false then
        on_confirm()
      end
    end,
  }

  local engine = setmetatable({}, {
    __index = function(_, name)
      return function(...)
        local args = { ... }
        H.calls[#H.calls + 1] = { method = name, args = args, n = select("#", ...) }
        local result = opts.results and opts.results[name] or { true, nil }
        for _, arg in ipairs(args) do
          if type(arg) == "function" then
            arg(unpack(result, 1, table.maxn(result)))
            return
          end
        end
        return unpack(result, 1, table.maxn(result))
      end
    end,
  })

  package.loaded["sandbox"] = {
    get_engine = function()
      if opts.no_engine then
        return nil
      end
      return engine
    end,
    get_compose_engine = function()
      if opts.no_engine then
        return nil
      end
      return engine
    end,
    resolve_engine_name = function()
      if opts.no_engine then
        return nil
      end
      return "docker"
    end,
  }

  for _, view in ipairs({
    "list_view",
    "log_view",
    "inspect_view",
    "error_view",
    "volume_list_view",
    "network_list_view",
    "image_list_view_docker",
    "image_list_view_podman",
    "log_follow_view",
  }) do
    local name = view
    package.loaded["sandbox.ui." .. name] = function(...)
      H.views[#H.views + 1] = { view = name, args = { ... } }
    end
  end

  for _, module in ipairs({
    "container_commands",
    "image_commands",
    "volume_commands",
    "network_commands",
  }) do
    package.loaded["sandbox.bindings.usrcmds." .. module] = nil
  end

  return H
end

local function cleanup()
  for _, name in ipairs({
    "sandbox",
    "sandbox.notify",
    "sandbox.util.confirm",
    "sandbox.ui.list_view",
    "sandbox.ui.log_view",
    "sandbox.ui.inspect_view",
    "sandbox.ui.error_view",
    "sandbox.ui.volume_list_view",
    "sandbox.ui.network_list_view",
    "sandbox.ui.image_list_view_docker",
    "sandbox.ui.image_list_view_podman",
    "sandbox.ui.log_follow_view",
    "sandbox.bindings.usrcmds.container_commands",
    "sandbox.bindings.usrcmds.image_commands",
    "sandbox.bindings.usrcmds.volume_commands",
    "sandbox.bindings.usrcmds.network_commands",
    "sandbox.bindings.usrcmds.container_commands_buffer",
  }) do
    package.loaded[name] = nil
  end
end

--- @param module string
--- @return table
local function load(module)
  return require("sandbox.bindings.usrcmds." .. module)
end

--- @param H CommandsHarness
--- @param method string
--- @return table|nil
local function call_of(H, method)
  for _, c in ipairs(H.calls) do
    if c.method == method then
      return c
    end
  end
  return nil
end

--- @param H CommandsHarness
--- @param level string
--- @return table|nil
local function notice_of(H, level)
  for _, n in ipairs(H.notices) do
    if n.level == level then
      return n
    end
  end
  return nil
end

describe("usrcmds command layer: the usage guard", function()
  after_each(cleanup)

  -- Every entry is "the argument is missing or empty" for one subcommand. The
  -- engine must not be touched, and the user must get the usage line.
  local CASES = {
    { module = "container_commands", fn = "logs", args = { "" } },
    { module = "container_commands", fn = "logs_follow", args = { "" } },
    { module = "container_commands", fn = "exec", args = { nil } },
    { module = "container_commands", fn = "exec_once", args = { "" } },
    { module = "container_commands", fn = "start", args = { "" } },
    { module = "container_commands", fn = "stop", args = { nil } },
    { module = "container_commands", fn = "kill", args = { "" } },
    { module = "container_commands", fn = "restart", args = { "" } },
    { module = "container_commands", fn = "pause", args = { "" } },
    { module = "container_commands", fn = "unpause", args = { "" } },
    { module = "container_commands", fn = "rename", args = { "abc", "" } },
    { module = "container_commands", fn = "rename", args = { "", "web" } },
    { module = "container_commands", fn = "stats", args = { "" } },
    { module = "container_commands", fn = "top", args = { "" } },
    { module = "container_commands", fn = "cp", args = { "src", "" } },
    { module = "container_commands", fn = "cp", args = { "", "dest" } },
    { module = "container_commands", fn = "remove", args = { "" } },
    { module = "container_commands", fn = "inspect", args = { "" } },
    { module = "image_commands", fn = "pull", args = { "" } },
    { module = "image_commands", fn = "push", args = { "" } },
    { module = "image_commands", fn = "remove", args = { "" } },
    { module = "image_commands", fn = "tag", args = { "src", "" } },
    { module = "image_commands", fn = "save", args = { "img", "" } },
    { module = "image_commands", fn = "load", args = { "" } },
    { module = "image_commands", fn = "history", args = { "" } },
    { module = "image_commands", fn = "inspect", args = { "" } },
    { module = "volume_commands", fn = "create", args = { "" } },
    { module = "volume_commands", fn = "remove", args = { "" } },
    { module = "volume_commands", fn = "inspect", args = { "" } },
    { module = "network_commands", fn = "create", args = { "" } },
    { module = "network_commands", fn = "remove", args = { "" } },
    { module = "network_commands", fn = "inspect", args = { "" } },
    { module = "network_commands", fn = "connect", args = { "net", "" } },
    { module = "network_commands", fn = "disconnect", args = { "", "abc" } },
  }

  for _, case in ipairs(CASES) do
    local label = case.module:gsub("_commands", "")
      .. " "
      .. case.fn
      .. "("
      .. vim.inspect(case.args):gsub("%s+", " ")
      .. ")"
    it(label .. " warns instead of calling the engine", function()
      local H = harness({})
      local mod = load(case.module)

      mod[case.fn](unpack(case.args, 1, 3))

      local warning = notice_of(H, "warn")
      assert.is_not_nil(warning, label .. ": no warning")
      assert.is_truthy(warning.msg:find("Usage:", 1, true), label .. ": " .. warning.msg)
      assert.are.same({}, H.calls, label .. ": the engine was asked anyway")
      assert.are.same({}, H.confirms, label .. ": a confirmation was asked for a refused call")
    end)
  end
end)

describe("usrcmds command layer: the no-engine guard", function()
  after_each(cleanup)

  -- `sandbox.get_engine` has already reported the problem by the time it
  -- returns nil, so these must stop quietly rather than report twice.
  local CASES = {
    { module = "container_commands", fn = "list", args = {} },
    { module = "container_commands", fn = "logs", args = { "abc" } },
    { module = "container_commands", fn = "start", args = { "abc" } },
    { module = "container_commands", fn = "stop", args = { "abc" } },
    { module = "container_commands", fn = "kill", args = { "abc" } },
    { module = "container_commands", fn = "remove", args = { "abc" } },
    { module = "container_commands", fn = "prune", args = {} },
    { module = "container_commands", fn = "run", args = {} },
    { module = "container_commands", fn = "exec", args = { "abc" } },
    { module = "container_commands", fn = "exec_once", args = { "abc" } },
    { module = "container_commands", fn = "inspect", args = { "abc" } },
    { module = "image_commands", fn = "list", args = {} },
    { module = "image_commands", fn = "pull", args = { "nginx" } },
    { module = "image_commands", fn = "prune", args = {} },
    { module = "volume_commands", fn = "list", args = {} },
    { module = "volume_commands", fn = "prune", args = {} },
    { module = "network_commands", fn = "list", args = {} },
    { module = "network_commands", fn = "prune", args = {} },
  }

  for _, case in ipairs(CASES) do
    local label = case.module:gsub("_commands", "") .. " " .. case.fn
    it(label .. " stops without touching the engine or reporting twice", function()
      local H = harness({ no_engine = true })
      local mod = load(case.module)

      mod[case.fn](unpack(case.args, 1, 2))

      assert.are.same({}, H.calls, label)
      assert.are.same({}, H.notices, label)
      assert.are.same({}, H.confirms, label)
    end)
  end
end)

describe("usrcmds command layer: the destructive gate", function()
  after_each(cleanup)

  local CASES = {
    {
      module = "container_commands",
      fn = "kill",
      args = { "abc123" },
      method = "kill_container",
      prompt = "Kill container abc123?",
    },
    {
      module = "container_commands",
      fn = "remove",
      args = { "abc123" },
      method = "remove_container",
      prompt = "Remove container abc123?",
    },
    {
      module = "container_commands",
      fn = "prune",
      args = {},
      method = "prune_containers",
      prompt = "Prune all stopped containers?",
    },
    {
      module = "image_commands",
      fn = "remove",
      args = { "nginx" },
      method = "remove_image",
      prompt = "Remove image nginx?",
    },
    {
      module = "image_commands",
      fn = "prune",
      args = {},
      method = "prune_images",
      prompt = "Prune all dangling images?",
    },
    {
      module = "volume_commands",
      fn = "remove",
      args = { "data" },
      method = "remove_volume",
      prompt = "Remove volume data?",
    },
    {
      module = "volume_commands",
      fn = "prune",
      args = {},
      method = "prune_volumes",
      prompt = "Prune all unused volumes?",
    },
    {
      module = "network_commands",
      fn = "remove",
      args = { "bridge" },
      method = "remove_network",
      prompt = "Remove network bridge?",
    },
    {
      module = "network_commands",
      fn = "prune",
      args = {},
      method = "prune_networks",
      prompt = "Prune all unused networks?",
    },
  }

  for _, case in ipairs(CASES) do
    local label = case.module:gsub("_commands", "") .. " " .. case.fn

    it(label .. " asks before it acts", function()
      local H = harness({})
      load(case.module)[case.fn](unpack(case.args, 1, 1))

      assert.are.same({ case.prompt }, H.confirms, label)
      assert.is_not_nil(call_of(H, case.method), label .. ": the engine was never reached after a yes")
    end)

    it(label .. " does not touch the engine on a no", function()
      local H = harness({ answer = false })
      load(case.module)[case.fn](unpack(case.args, 1, 1))

      assert.are.same({ case.prompt }, H.confirms, label)
      assert.are.same({}, H.calls, label .. ": a declined action reached the engine")
      assert.are.same({}, H.notices, label .. ": a declined action reported something")
    end)
  end

  it("asks nothing before a non-destructive verb", function()
    local H = harness({})
    local containers = load("container_commands")

    containers.start("abc123")
    containers.stop("abc123")
    containers.restart("abc123")
    containers.pause("abc123")
    containers.unpause("abc123")
    containers.rename("abc123", "web")

    assert.are.same({}, H.confirms)
  end)
end)

describe("usrcmds command layer: results reach the right view", function()
  after_each(cleanup)

  it("container list renders the list view", function()
    local H = harness({ results = { list_containers = { { { id = "c1", name = "web", status = "running" } }, nil } } })

    load("container_commands").list()

    assert.are.equal("list_view", H.views[1].view)
    assert.are.equal("web", H.views[1].args[1][1].name)
  end)

  it("container list shows the failure in the error view, not a popup", function()
    local H = harness({ results = { list_containers = { nil, "Cannot connect to the Docker daemon" } } })

    load("container_commands").list()

    assert.are.equal("error_view", H.views[1].view)
    assert.are.same({ "Failed to list containers:", "Cannot connect to the Docker daemon" }, H.views[1].args[1])
  end)

  it("container list warns about partially unparsable output but still renders", function()
    local H = harness({ results = { list_containers = { { { name = "web" } }, "JSON decode error(s):\njunk" } } })

    load("container_commands").list()

    assert.are.equal("list_view", H.views[1].view)
    assert.is_truthy(notice_of(H, "warn").msg:find("Some containers could not be parsed", 1, true))
  end)

  it("container logs go to the log view, keyed by the container", function()
    local H = harness({ results = { get_logs = { { "line one", "line two" }, nil } } })

    load("container_commands").logs("abc123")

    assert.are.equal("log_view", H.views[1].view)
    assert.are.same({ "line one", "line two" }, H.views[1].args[1])
    assert.are.equal("abc123", H.views[1].args[2])
  end)

  it("stats and top get their own log-view names, so they cannot collide", function()
    local H = harness({ results = { stats_container = { { "s" }, nil }, top_container = { { "t" }, nil } } })
    local containers = load("container_commands")

    containers.stats("abc123")
    containers.top("abc123")

    assert.are.equal("stats/abc123", H.views[1].args[2])
    assert.are.equal("top/abc123", H.views[2].args[2])
  end)

  it("container inspect hands the decoded table to the inspect view", function()
    local H = harness({ results = { inspect_container = { { Id = "abc123" } } } })

    load("container_commands").inspect("abc123")

    assert.are.equal("inspect_view", H.views[1].view)
    assert.are.equal("abc123", H.views[1].args[1].Id)
  end)

  it("logs-follow hands the engine itself to the follow view -- it needs to stream", function()
    local H = harness({})

    load("container_commands").logs_follow("abc123")

    assert.are.equal("log_follow_view", H.views[1].view)
    assert.are.equal("abc123", H.views[1].args[2])
  end)

  it("volume and network lists render their own views", function()
    local H = harness({
      results = { list_volumes = { { { name = "data" } }, nil }, list_networks = { { { name = "bridge" } }, nil } },
    })

    load("volume_commands").list()
    load("network_commands").list()

    assert.are.equal("volume_list_view", H.views[1].view)
    assert.are.equal("network_list_view", H.views[2].view)
  end)

  it("volume inspect survives an engine that does not implement it", function()
    local H = harness({})
    package.loaded["sandbox"].get_engine = function()
      return {
        inspect_volume = function()
          error("inspect_volume not implemented.")
        end,
      }
    end

    load("volume_commands").inspect("data")

    assert.is_truthy(notice_of(H, "error").msg:find("Failed to inspect volume data", 1, true))
    assert.are.same({}, H.views)
  end)
end)

describe("usrcmds command layer: what the user is told", function()
  after_each(cleanup)

  it("reports a failed start with the friendly text and logs the raw one", function()
    local H = harness({ results = { start_container = { false, "Cannot connect to the Docker daemon at ..." } } })

    load("container_commands").start("abc123")

    local err = notice_of(H, "error")
    assert.is_truthy(err.msg:find("Failed to start container abc123", 1, true))
    assert.is_truthy(err.msg:find("Docker daemon not reachable", 1, true), err.msg)
    -- The raw text is not thrown away: it goes to the logger as context.
    assert.are.equal("Cannot connect to the Docker daemon at ...", err.ctx.err)
  end)

  it("confirms a successful start by name", function()
    local H = harness({})

    load("container_commands").start("abc123")

    assert.are.equal("Container started successfully: abc123", notice_of(H, "info").msg)
  end)

  it("adds the likely cause when removing a container fails", function()
    local H = harness({ results = { remove_container = { false, "container is running" } } })

    load("container_commands").remove("abc123")

    assert.is_truthy(notice_of(H, "error").msg:find("Is it stopped?", 1, true))
  end)

  it("names both sides when a copy fails", function()
    local H = harness({ results = { cp_container = { false, "no such file" } } })

    load("container_commands").cp("./a.txt", "abc123:/app/a.txt")

    local err = notice_of(H, "error")
    assert.is_truthy(err.msg:find("./a.txt -> abc123:/app/a.txt", 1, true))
    assert.are.equal("./a.txt", err.ctx.src)
    assert.are.equal("abc123:/app/a.txt", err.ctx.dest)
  end)

  it("reports the rename as old -> new", function()
    local H = harness({})

    load("container_commands").rename("abc123", "web-2")

    assert.are.equal("Container renamed: abc123 -> web-2", notice_of(H, "info").msg)
  end)
end)

describe("usrcmds container exec", function()
  after_each(cleanup)

  it("uses the configured default shell when none is given", function()
    local H = harness({})
    package.loaded["sandbox.config"] = nil
    require("sandbox.config").options.default_shell = "fish"

    load("container_commands").exec("abc123")

    assert.are.same({ "fish" }, call_of(H, "exec_in_container").args[2])
    package.loaded["sandbox.config"] = nil
  end)

  it("prefers the shell the caller named", function()
    local H = harness({})

    load("container_commands").exec("abc123", "zsh", "/app")

    local call = call_of(H, "exec_in_container")
    assert.are.same({ "zsh" }, call.args[2])
    assert.are.equal("/app", call.args[3])
  end)

  it("passes an empty exec-once command as nil, not as an empty list", function()
    local H = harness({})

    load("container_commands").exec_once("abc123", {})

    assert.is_nil(call_of(H, "exec_in_container").args[2])
  end)

  it("forwards the workdir of a one-off command", function()
    local H = harness({})

    load("container_commands").exec_once("abc123", { "ls" }, "/srv")

    local call = call_of(H, "exec_in_container")
    assert.are.same({ "ls" }, call.args[2])
    assert.are.equal("/srv", call.args[3])
  end)

  it("reports an engine that cannot exec instead of raising out of the command", function()
    local H = harness({})
    package.loaded["sandbox"].get_engine = function()
      return {
        exec_in_container = function()
          error("exec_in_container not implemented.")
        end,
      }
    end

    assert.has_no.errors(function()
      load("container_commands").exec("abc123")
    end)
    assert.is_truthy(notice_of(H, "error").msg:find("Failed to exec in container abc123", 1, true))
  end)
end)

describe("usrcmds image commands", function()
  after_each(cleanup)

  it("picks the podman image view for podman and the docker one otherwise", function()
    local H = harness({ results = { list_images = { { { id = "i1" } }, nil } } })
    local images = load("image_commands")

    images.list()
    assert.are.equal("image_list_view_docker", H.views[1].view)

    package.loaded["sandbox"].resolve_engine_name = function()
      return "podman"
    end
    images.list()
    assert.are.equal("image_list_view_podman", H.views[2].view)
  end)

  it("reports a pull by name once it is done", function()
    local H = harness({})

    load("image_commands").pull("nginx:latest")

    assert.is_truthy(notice_of(H, "info").msg:find("nginx:latest", 1, true))
  end)

  it("reports a failed pull with the friendly text", function()
    local H = harness({ results = { pull_image = { false, "manifest unknown" } } })

    load("image_commands").pull("nope:latest")

    assert.is_truthy(notice_of(H, "error").msg:find("manifest unknown", 1, true))
  end)

  it("passes save's two arguments in the documented order", function()
    local H = harness({})

    load("image_commands").save("nginx:latest", "/tmp/nginx.tar")

    local call = call_of(H, "save_image")
    assert.are.equal("nginx:latest", call.args[1])
    assert.are.equal("/tmp/nginx.tar", call.args[2])
  end)
end)

describe("usrcmds container_commands_buffer", function()
  local real_jobstart, real_termopen, real_feedkeys
  local captured

  before_each(function()
    captured = nil
    real_jobstart, real_termopen, real_feedkeys = vim.fn.jobstart, vim.fn.termopen, vim.api.nvim_feedkeys
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.fn.jobstart = function(cmd)
      captured = cmd
      return 1
    end
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.fn.termopen = function(cmd)
      captured = cmd
      return 1
    end
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.api.nvim_feedkeys = function(...) end
  end)

  after_each(function()
    vim.fn.jobstart, vim.fn.termopen, vim.api.nvim_feedkeys = real_jobstart, real_termopen, real_feedkeys
    cleanup()
    vim.cmd("silent! %bwipeout!")
  end)

  --- The terminal variants build their argv themselves instead of going
  --- through the adapters, so these are pinned separately -- a change to an
  --- adapter's argv does not reach them.
  local CASES = {
    { fn = "start", args = { "abc123" }, argv = { "docker", "start", "abc123" }, buf = "term/start/abc123" },
    {
      fn = "stop",
      args = { "abc123" },
      argv = { "docker", "stop", "--time=1", "abc123" },
      buf = "term/stop/abc123",
    },
    { fn = "kill", args = { "abc123" }, argv = { "docker", "kill", "abc123" }, buf = "term/kill/abc123" },
    {
      fn = "restart",
      args = { "abc123" },
      argv = { "docker", "restart", "abc123" },
      buf = "term/restart/abc123",
    },
    { fn = "remove", args = { "abc123" }, argv = { "docker", "rm", "abc123" }, buf = "term/remove/abc123" },
    { fn = "prune", args = {}, argv = { "docker", "container", "prune", "-f" }, buf = "term/prune" },
    { fn = "pull", args = { "nginx" }, argv = { "docker", "pull", "nginx" }, buf = "term/pull/nginx" },
    {
      fn = "build",
      args = { "my-tag", "./ctx" },
      argv = { "docker", "build", "-t", "my-tag", "./ctx" },
      buf = "term/build/my-tag",
    },
    { fn = "image_prune", args = {}, argv = { "docker", "image", "prune", "-f" }, buf = "term/image-prune" },
  }

  for _, case in ipairs(CASES) do
    it(case.fn .. " streams `" .. table.concat(case.argv, " ") .. "` into its own named buffer", function()
      harness({})
      local buffer_cmds = require("sandbox.bindings.usrcmds.container_commands_buffer")

      buffer_cmds[case.fn](unpack(case.args, 1, 2))

      assert.are.same(case.argv, captured)
      assert.are.equal("sandbox.nvim://" .. case.buf, vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf()))
    end)
  end

  it("defaults build's context to the cwd", function()
    harness({})
    require("sandbox.bindings.usrcmds.container_commands_buffer").build("my-tag")

    assert.are.same({ "docker", "build", "-t", "my-tag", "." }, captured)
  end)

  it("still asks before the destructive ones", function()
    local H = harness({ answer = false })
    local buffer_cmds = require("sandbox.bindings.usrcmds.container_commands_buffer")

    buffer_cmds.kill("abc123")
    buffer_cmds.remove("abc123")
    buffer_cmds.prune()
    buffer_cmds.image_prune()

    assert.are.equal(4, #H.confirms)
    assert.is_nil(captured, "a declined action spawned a terminal anyway")
  end)

  it("reuses the buffer name rather than stacking up one terminal per invocation", function()
    harness({})
    local buffer_cmds = require("sandbox.bindings.usrcmds.container_commands_buffer")

    buffer_cmds.start("abc123")
    buffer_cmds.start("abc123")

    local matching = 0
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_get_name(buf) == "sandbox.nvim://term/start/abc123" then
        matching = matching + 1
      end
    end
    assert.are.equal(1, matching)
  end)

  it("says so when no engine resolves, rather than spawning `nil start abc`", function()
    local H = harness({ no_engine = true })

    require("sandbox.bindings.usrcmds.container_commands_buffer").start("abc123")

    assert.are.equal("No engine configured", notice_of(H, "error").msg)
    assert.is_nil(captured)
  end)
end)
