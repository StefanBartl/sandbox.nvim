-- The wiring layer: `:Sandbox` / `:Sbx` and the ~60 routes hanging off them.
--
-- Two halves, because they fail differently:
--
--   1. The route *table* -- driven against a recording composer. A route with
--      no `desc`, a duplicated path or an argument typed against a type that
--      was never registered is a defect that no user ever sees as an error
--      message; it just makes `<Tab>` or `:h` quietly wrong.
--   2. The *dispatch* -- driven through the real `lib.nvim` composer and real
--      Ex commands, with every command module replaced by a recorder. This is
--      the only place the argument plumbing (`command_tail`, `exec_workdir`,
--      the `--buffer` flag) is exercised end to end; called directly, those
--      three are unreachable locals.
--
-- Nothing reaches an engine: the command modules are recorders, so no route's
-- body runs past the boundary of this file.
---@diagnostic disable: need-check-nil

local MODULES = {
  container_commands = {
    "list",
    "logs",
    "logs_follow",
    "exec",
    "exec_once",
    "start",
    "stop",
    "kill",
    "restart",
    "pause",
    "unpause",
    "rename",
    "stats",
    "top",
    "cp",
    "run",
    "remove",
    "prune",
    "inspect",
  },
  container_commands_buffer = {
    "start",
    "stop",
    "kill",
    "restart",
    "remove",
    "prune",
    "pull",
    "build",
    "image_prune",
  },
  image_commands = { "list", "pull", "push", "remove", "tag", "save", "load", "history", "inspect", "prune" },
  volume_commands = { "list", "create", "remove", "inspect", "prune" },
  network_commands = { "list", "create", "remove", "inspect", "connect", "disconnect", "prune" },
  compose_commands = { "up", "down", "restart", "ps", "services", "logs" },
  engine_commands = { "set", "get", "reset", "cycle" },
  registry_commands = { "login", "logout" },
  devcontainer_commands = { "build", "attach", "lazygit" },
  wsl_commands = {
    "list",
    "start",
    "stop",
    "set_default",
    "set_version",
    "exec",
    "export",
    "import",
    "shutdown_all",
  },
}

--- Replace every command module with a recorder.
--- @param wsl_available boolean
--- @return table log
local function stub_command_modules(wsl_available)
  local log = {}
  for module, fns in pairs(MODULES) do
    local stub = {}
    for _, fn in ipairs(fns) do
      stub[fn] = function(...)
        log[#log + 1] = { module = module, fn = fn, args = { ... }, n = select("#", ...) }
      end
    end
    if module == "wsl_commands" then
      stub.available = function()
        return wsl_available
      end
    end
    package.loaded["sandbox.bindings.usrcmds." .. module] = stub
  end
  return log
end

local function forget_stubs()
  for module in pairs(MODULES) do
    package.loaded["sandbox.bindings.usrcmds." .. module] = nil
  end
  package.loaded["sandbox.bindings.usrcmds"] = nil
end

describe("bindings.usrcmds route table", function()
  local real_composer

  --- @param wsl_available boolean
  --- @return table routes, table spec_by_name, table types
  local function collect(wsl_available)
    forget_stubs()
    stub_command_modules(wsl_available)

    local specs, types = {}, {}
    real_composer = package.loaded["lib.nvim.bindings.usercmd.composer"]
    package.loaded["lib.nvim.bindings.usercmd.composer"] = {
      register_type = function(name, def)
        types[name] = def
      end,
      verb = function(name, spec)
        specs[name] = spec
      end,
      document = function()
        return true
      end,
    }

    require("sandbox.bindings.usrcmds").setup()
    return specs["Sandbox"].routes, specs, types
  end

  after_each(function()
    package.loaded["lib.nvim.bindings.usercmd.composer"] = real_composer
    forget_stubs()
  end)

  it("registers the same spec under both :Sandbox and its :Sbx alias", function()
    local _, specs = collect(true)

    assert.is_not_nil(specs["Sandbox"])
    assert.is_not_nil(specs["Sbx"])
    assert.are.equal(specs["Sandbox"], specs["Sbx"])
    assert.is_string(specs["Sandbox"].desc)
  end)

  it("gives every route a path, a description and a runnable body", function()
    local routes = collect(true)

    assert.is_true(#routes > 50, "expected the full route set, got " .. #routes)
    for _, route in ipairs(routes) do
      local label = table.concat(route.path or { "?" }, " ")
      assert.is_table(route.path, label .. ": no path")
      assert.are.equal(2, #route.path, label .. ": paths are <namespace> <verb>")
      assert.is_string(route.desc, label .. ": no desc")
      assert.is_true(#route.desc > 0, label .. ": empty desc")
      assert.is_function(route.run, label .. ": run is not a function")
    end
  end)

  it("has no duplicate route paths", function()
    local routes = collect(true)
    local seen = {}
    local duplicates = {}
    for _, route in ipairs(routes) do
      local key = table.concat(route.path, " ")
      if seen[key] then
        duplicates[#duplicates + 1] = key
      end
      seen[key] = true
    end

    assert.are.same({}, duplicates)
  end)

  it("covers the ten documented namespaces", function()
    local routes = collect(true)
    local namespaces = {}
    for _, route in ipairs(routes) do
      namespaces[route.path[1]] = true
    end

    for _, expected in ipairs({
      "container",
      "image",
      "volume",
      "network",
      "compose",
      "engine",
      "registry",
      "docs",
      "devcontainer",
      "wsl",
    }) do
      assert.is_true(namespaces[expected] == true, "no routes in namespace " .. expected)
    end
  end)

  it("omits the wsl namespace entirely where wsl.exe is unreachable", function()
    local routes = collect(false)

    for _, route in ipairs(routes) do
      assert.are_not.equal("wsl", route.path[1])
    end
  end)

  it("types every id argument against a type it also registers", function()
    local routes, _, types = collect(true)

    for _, route in ipairs(routes) do
      for _, arg in ipairs(route.args or {}) do
        if arg.type ~= "STRING" then
          assert.is_not_nil(types[arg.type], table.concat(route.path, " ") .. ": unregistered type " .. arg.type)
        end
      end
    end

    -- All five dynamic types exist and can both validate and complete.
    for _, name in ipairs({ "CONTAINER_ID", "IMAGE_ID", "VOLUME_NAME", "NETWORK_NAME", "DISTRO_NAME" }) do
      assert.is_function(types[name].validate, name)
      assert.is_function(types[name].complete, name)
    end
  end)

  it("offers --buffer only on the routes whose buffer variant exists", function()
    local routes = collect(true)
    local with_flag = {}
    for _, route in ipairs(routes) do
      for _, flag in ipairs(route.flags or {}) do
        if flag.name == "buffer" then
          with_flag[table.concat(route.path, " ")] = true
        end
      end
    end

    assert.are.same({
      ["container start"] = true,
      ["container stop"] = true,
      ["container kill"] = true,
      ["container restart"] = true,
      ["container remove"] = true,
      ["container prune"] = true,
      ["image pull"] = true,
      ["image prune"] = true,
    }, with_flag)
  end)
end)

describe("bindings.usrcmds completion types", function()
  local real_composer
  local types
  local fetches

  --- @class UsrcmdsCompletionOpts
  --- @field containers? table[]
  --- @field images? table[]
  --- @field volumes? table[]
  --- @field networks? table[]
  --- @field distros? table[]
  --- @field engine? boolean  # false makes get_engine() return nil
  --- @field raise? boolean  # the fetch throws
  --- @field ttl? integer

  --- @param opts UsrcmdsCompletionOpts
  local function install(opts)
    forget_stubs()
    stub_command_modules(true)
    fetches = { containers = 0, images = 0, volumes = 0, networks = 0, distros = 0 }

    types = {}
    real_composer = package.loaded["lib.nvim.bindings.usercmd.composer"]
    package.loaded["lib.nvim.bindings.usercmd.composer"] = {
      register_type = function(name, def)
        types[name] = def
      end,
      verb = function() end,
      document = function()
        return true
      end,
    }

    package.loaded["sandbox.config"] = nil
    require("sandbox.config").options.completion_cache_ttl_ms = opts.ttl or 60000

    package.loaded["sandbox"] = {
      get_engine = function()
        if opts.engine == false then
          return nil
        end
        return { name = "fake" }
      end,
    }

    local function usecase(kind, items)
      return function()
        fetches[kind] = fetches[kind] + 1
        if opts.raise then
          error("boom")
        end
        return items
      end
    end

    package.loaded["sandbox.core.usecases.containers.list_containers"] = usecase("containers", opts.containers)
    package.loaded["sandbox.core.usecases.images.list_images"] = usecase("images", opts.images)
    package.loaded["sandbox.core.usecases.volumes.list_volumes"] = usecase("volumes", opts.volumes)
    package.loaded["sandbox.core.usecases.networks.list_networks"] = usecase("networks", opts.networks)
    package.loaded["sandbox.core.usecases.wsl.list_distros"] = usecase("distros", opts.distros)
    package.loaded["sandbox.adapters.wsl.engine"] = {}

    require("sandbox.bindings.usrcmds").setup()
  end

  after_each(function()
    package.loaded["lib.nvim.bindings.usercmd.composer"] = real_composer
    for _, name in ipairs({
      "sandbox.core.usecases.containers.list_containers",
      "sandbox.core.usecases.images.list_images",
      "sandbox.core.usecases.volumes.list_volumes",
      "sandbox.core.usecases.networks.list_networks",
      "sandbox.core.usecases.wsl.list_distros",
      "sandbox.adapters.wsl.engine",
      "sandbox",
      "sandbox.config",
    }) do
      package.loaded[name] = nil
    end
    forget_stubs()
  end)

  it("completes container names, filtered by what is already typed", function()
    install({ containers = { { name = "web" }, { name = "worker" }, { name = "db" } } })

    assert.are.same({ "web", "worker", "db" }, types.CONTAINER_ID.complete(""))
    assert.are.same({ "web", "worker" }, types.CONTAINER_ID.complete("w"))
    assert.are.same({}, types.CONTAINER_ID.complete("zzz"))
  end)

  it("completes images as repository:tag", function()
    install({ images = { { repository = "nginx", tag = "latest" }, { repository = "alpine", tag = "3.20" } } })

    assert.are.same({ "nginx:latest", "alpine:3.20" }, types.IMAGE_ID.complete(""))
  end)

  it("completes volumes, networks and distros by name", function()
    install({
      volumes = { { name = "data" } },
      networks = { { name = "bridge" } },
      distros = { { name = "Ubuntu-24.04" } },
    })

    assert.are.same({ "data" }, types.VOLUME_NAME.complete(""))
    assert.are.same({ "bridge" }, types.NETWORK_NAME.complete(""))
    assert.are.same({ "Ubuntu-24.04" }, types.DISTRO_NAME.complete(""))
  end)

  it("asks the engine once per TTL, not once per <Tab>", function()
    install({ containers = { { name = "web" } } })

    for _ = 1, 25 do
      types.CONTAINER_ID.complete("w")
    end

    assert.are.equal(1, fetches.containers)
  end)

  it("asks again once the cache has expired", function()
    install({ containers = { { name = "web" } }, ttl = 0 })

    types.CONTAINER_ID.complete("")
    types.CONTAINER_ID.complete("")

    assert.are.equal(2, fetches.containers)
  end)

  -- PERF-46: the cache key must contain every parameter that influences the
  -- result -- here, which engine answered. Without the engine in the key,
  -- `<Tab>` kept offering the previous engine's names after `:Sandbox
  -- engine set` or a `.sandboxrc`-pinning `:cd`, until the entry aged out.
  it("keys the cache by the resolved engine, not just the list kind", function()
    install({ containers = { { name = "web" } } })
    package.loaded["sandbox"].resolve_engine_name = function()
      return "docker"
    end

    assert.are.same({ "web" }, types.CONTAINER_ID.complete(""))

    package.loaded["sandbox"].resolve_engine_name = function()
      return "podman"
    end
    package.loaded["sandbox.core.usecases.containers.list_containers"] = function()
      fetches.containers = fetches.containers + 1
      return { { name = "postgres" } }
    end

    assert.are.same({ "postgres" }, types.CONTAINER_ID.complete(""))
  end)

  it("degrades to no candidates when the engine is unusable, and stays silent", function()
    -- A notify(ERROR) fired while Neovim computes <Tab> candidates surfaces
    -- as a hard error to the caller, which is why the fetch runs with notify
    -- muted. The mute must be undone afterwards either way.
    install({ raise = true })
    local notified = false
    local real_notify = vim.notify
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.notify = function()
      notified = true
    end

    local candidates = types.CONTAINER_ID.complete("")

    local restored = vim.notify
    vim.notify = real_notify

    assert.are.same({}, candidates)
    assert.is_false(notified)
    assert.are.equal("function", type(restored), "vim.notify must be restored after the fetch, even when it raised")
  end)

  it("offers nothing rather than crashing when no engine resolves", function()
    install({ engine = false })

    assert.are.same({}, types.CONTAINER_ID.complete(""))
    assert.are.equal(0, fetches.containers)
  end)

  it("skips an item whose name cannot be built instead of dropping the whole list", function()
    install({ images = { { repository = "nginx", tag = "latest" }, { repository = nil, tag = "x" } } })

    -- The second entry makes `repository .. ":" .. tag` raise; the first must
    -- still be offered.
    assert.are.same({ "nginx:latest" }, types.IMAGE_ID.complete(""))
  end)

  it("validates any raw value -- an id the engine has never heard of is still accepted", function()
    install({})

    local ok, value, err = types.CONTAINER_ID.validate("not-a-real-id")

    assert.is_true(ok)
    assert.are.equal("not-a-real-id", value)
    assert.is_nil(err)
  end)
end)

describe("bindings.usrcmds dispatch through the real composer", function()
  local log

  before_each(function()
    forget_stubs()
    log = stub_command_modules(true)
    package.loaded["sandbox"] = {
      get_engine = function()
        return { name = "fake" }
      end,
    }
    require("sandbox.bindings.usrcmds").setup()
  end)

  after_each(function()
    pcall(vim.api.nvim_del_user_command, "Sandbox")
    pcall(vim.api.nvim_del_user_command, "Sbx")
    package.loaded["sandbox"] = nil
    forget_stubs()
  end)

  --- @param fn string
  --- @return table|nil
  local function last(fn)
    for i = #log, 1, -1 do
      if log[i].fn == fn then
        return log[i]
      end
    end
    return nil
  end

  it("creates both :Sandbox and :Sbx", function()
    assert.are.equal(2, vim.fn.exists(":Sandbox"))
    assert.are.equal(2, vim.fn.exists(":Sbx"))
  end)

  it("routes a bare subcommand", function()
    vim.cmd("Sandbox container list")

    assert.are.equal("container_commands", last("list").module)
  end)

  it("routes through the short alias identically", function()
    vim.cmd("Sbx volume list")

    assert.are.equal("volume_commands", last("list").module)
  end)

  it("passes a positional argument along", function()
    vim.cmd("Sandbox container logs abc123")

    assert.are.same({ "abc123" }, last("logs").args)
  end)

  it("passes both positionals of a two-argument route in order", function()
    vim.cmd("Sandbox container rename abc123 web-2")

    assert.are.same({ "abc123", "web-2" }, last("rename").args)
  end)

  it("reads workdir= as a kv, not as a positional", function()
    vim.cmd("Sandbox container exec abc123 bash workdir=/app")

    assert.are.same({ "abc123", "bash", "/app" }, last("exec").args)
  end)

  it("treats an empty workdir= as none given", function()
    vim.cmd("Sandbox container exec abc123 bash workdir=")

    assert.are.same({ "abc123", "bash" }, last("exec").args)
  end)

  it("leaves the shell optional", function()
    vim.cmd("Sandbox container exec abc123")

    assert.are.same({ "abc123" }, last("exec").args)
  end)

  it("collects every token after the id into the command tail", function()
    vim.cmd("Sandbox container exec-once abc123 ls -la /srv")

    local call = last("exec_once")
    assert.are.equal("abc123", call.args[1])
    assert.are.same({ "ls", "-la", "/srv" }, call.args[2])
  end)

  it("hands nil, not an empty list, to exec-once with no command", function()
    vim.cmd("Sandbox container exec-once abc123")

    assert.is_nil(last("exec_once").args[2])
  end)

  it("keeps the command tail and workdir= apart", function()
    vim.cmd("Sandbox container exec-once abc123 workdir=/srv ls -la")

    local call = last("exec_once")
    assert.are.same({ "ls", "-la" }, call.args[2])
    assert.are.equal("/srv", call.args[3])
  end)

  it("sends --buffer to the terminal-buffer variant", function()
    vim.cmd("Sandbox container start abc123 --buffer")

    assert.are.equal("container_commands_buffer", last("start").module)
  end)

  it("accepts the short -b for the same thing", function()
    vim.cmd("Sandbox container stop abc123 -b")

    assert.are.equal("container_commands_buffer", last("stop").module)
  end)

  it("sends the same subcommand without the flag to the notify variant", function()
    vim.cmd("Sandbox container start abc123")

    assert.are.equal("container_commands", last("start").module)
  end)

  it("routes image build straight to the buffer variant -- it has no quiet form", function()
    vim.cmd("Sandbox image build my-tag ./ctx")

    local call = last("build")
    assert.are.equal("container_commands_buffer", call.module)
    assert.are.same({ "my-tag", "./ctx" }, call.args)
  end)

  it("routes `image pull --buffer` to the buffer variant's pull", function()
    vim.cmd("Sandbox image pull nginx --buffer")

    assert.are.equal("container_commands_buffer", last("pull").module)
  end)

  it("routes the engine namespace", function()
    vim.cmd("Sandbox engine set docker")

    assert.are.same({ "docker" }, last("set").args)
  end)

  it("routes an optional-argument route with nothing given", function()
    vim.cmd("Sandbox registry logout")

    assert.are.equal("registry_commands", last("logout").module)
    assert.is_nil(last("logout").args[1])
  end)

  it("routes the wsl namespace, command tail included", function()
    vim.cmd("Sandbox wsl exec Ubuntu-24.04 ls -la")

    local call = last("exec")
    assert.are.equal("wsl_commands", call.module)
    assert.are.equal("Ubuntu-24.04", call.args[1])
    assert.are.same({ "ls", "-la" }, call.args[2])
  end)

  it("keeps a path with a space intact when it is the last argument", function()
    vim.cmd("Sandbox image save nginx:latest /tmp/my\\ image.tar")

    assert.are.same({ "nginx:latest", "/tmp/my image.tar" }, last("save").args)
  end)

  it("offers namespaces and verbs through Neovim's own completion", function()
    local namespaces = vim.fn.getcompletion("Sandbox ", "cmdline")
    assert.is_true(vim.tbl_contains(namespaces, "container"), vim.inspect(namespaces))

    local verbs = vim.fn.getcompletion("Sandbox container ", "cmdline")
    assert.is_true(vim.tbl_contains(verbs, "logs-follow"), vim.inspect(verbs))
  end)
end)
