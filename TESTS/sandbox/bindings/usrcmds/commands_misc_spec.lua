-- The four command modules that are not one resource per engine call:
-- compose (one project per detected file, no id argument), engine (session
-- switching), devcontainer (find/parse/derive a name), and wsl (its own
-- engine, its own availability gate).
--
-- Same approach as `commands_spec.lua`: recorded notify, recorded views, a
-- recording engine double, and the real use-case files in between. Nothing
-- spawns; `wsl list`'s buffer is a real scratch buffer, because what it writes
-- into it is the thing worth checking.
---@diagnostic disable: need-check-nil

--- @param opts { results?: table<string, any[]>, no_engine?: boolean, answer?: boolean|nil }
--- @return table
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
      if opts.answer ~= false then
        on_confirm()
      end
    end,
  }

  local engine = setmetatable({}, {
    __index = function(_, name)
      return function(...)
        local args = { ... }
        H.calls[#H.calls + 1] = { method = name, args = args }
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
  H.engine = engine

  package.loaded["sandbox"] = {
    get_engine = function()
      return not opts.no_engine and engine or nil
    end,
    get_compose_engine = function()
      return not opts.no_engine and engine or nil
    end,
    resolve_engine_name = function()
      return not opts.no_engine and "docker" or nil
    end,
  }

  for _, view in ipairs({ "log_view", "inspect_view", "error_view" }) do
    local name = view
    package.loaded["sandbox.ui." .. name] = function(...)
      H.views[#H.views + 1] = { view = name, args = { ... } }
    end
  end

  return H
end

local function cleanup()
  for _, name in ipairs({
    "sandbox",
    "sandbox.notify",
    "sandbox.util.confirm",
    "sandbox.util.compose_file",
    "sandbox.util.devcontainer_file",
    "sandbox.ui.log_view",
    "sandbox.ui.inspect_view",
    "sandbox.ui.error_view",
    "sandbox.engine_utils",
    "sandbox.core.usecases.devcontainer.build",
    "sandbox.adapters.wsl.engine",
    "sandbox.bindings.usrcmds.compose_commands",
    "sandbox.bindings.usrcmds.engine_commands",
    "sandbox.bindings.usrcmds.devcontainer_commands",
    "sandbox.bindings.usrcmds.wsl_commands",
    "sandbox.bindings.usrcmds.container_commands",
    "gitsuite.features.conflict",
  }) do
    package.loaded[name] = nil
  end
end

--- @param H table
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

describe("usrcmds compose_commands", function()
  after_each(cleanup)

  --- @param found string|nil
  --- @param services table|nil
  --- @param services_err string|nil
  local function with_file(found, services, services_err)
    package.loaded["sandbox.util.compose_file"] = {
      find = function()
        return found
      end,
      services = function()
        return services, services_err
      end,
    }
    package.loaded["sandbox.bindings.usrcmds.compose_commands"] = nil
    return require("sandbox.bindings.usrcmds.compose_commands")
  end

  local VERBS = { "up", "down", "restart", "ps", "services", "logs" }

  for _, verb in ipairs(VERBS) do
    it(verb .. " says which filenames it looked for when there is no compose file", function()
      local H = harness({})
      local compose = with_file(nil)

      compose[verb]()

      local warning = notice_of(H, "warn")
      assert.is_not_nil(warning, verb)
      assert.is_truthy(warning.msg:find("No docker%-compose%.yml"))
      assert.are.same({}, H.calls, verb .. ": asked the engine without a file")
    end)
  end

  it("passes the detected file to the compose engine, freshly resolved per call", function()
    local H = harness({})
    local compose = with_file("/proj/compose.yml")

    compose.up()

    assert.are.equal("up", H.calls[1].method)
    assert.are.equal("/proj/compose.yml", H.calls[1].args[1])
    assert.is_truthy(notice_of(H, "info").msg:find("/proj/compose.yml", 1, true))
  end)

  it("reports up/down/restart failures with the file that failed", function()
    local H = harness({
      results = {
        up = { false, "no such service" },
        down = { false, "no such service" },
        restart = { false, "no such service" },
      },
    })
    local compose = with_file("/proj/compose.yml")

    compose.up()
    compose.down()
    compose.restart()

    assert.are.equal(3, #H.notices)
    for _, notice in ipairs(H.notices) do
      assert.are.equal("error", notice.level)
      assert.are.equal("/proj/compose.yml", notice.ctx.file)
    end
  end)

  it("renders ps and logs into their own log-view buffers", function()
    local H = harness({ results = { ps = { { "svc  running" }, nil }, logs = { { "app | started" }, nil } } })
    local compose = with_file("/proj/compose.yml")

    compose.ps()
    compose.logs()

    assert.are.equal("compose-ps", H.views[1].args[2])
    assert.are.equal("compose-logs", H.views[2].args[2])
  end)

  it("reads the declared services statically, without asking the engine", function()
    local H = harness({})
    local compose = with_file("/proj/compose.yml", { "api", "db" })

    compose.services()

    assert.are.same({ "api", "db" }, H.views[1].args[1])
    assert.are.equal("compose-services", H.views[1].args[2])
    assert.are.same({}, H.calls)
  end)

  it("warns rather than opening an empty buffer when nothing is declared", function()
    local H = harness({})
    local compose = with_file("/proj/compose.yml", {})

    compose.services()

    assert.is_truthy(notice_of(H, "warn").msg:find("No services declared", 1, true))
    assert.are.same({}, H.views)
  end)

  it("passes the decoder's own error through, not a friendly rewrite", function()
    local H = harness({})
    local compose = with_file("/proj/compose.yml", nil, "'services:' is a list, not a map of service name -> config")

    compose.services()

    assert.is_truthy(notice_of(H, "error").msg:find("is a list, not a map", 1, true))
  end)

  it("stops when no compose engine resolves", function()
    local H = harness({ no_engine = true })
    local compose = with_file("/proj/compose.yml")

    compose.up()

    assert.are.same({}, H.calls)
    assert.are.same({}, H.notices)
  end)
end)

describe("usrcmds engine_commands", function()
  local forgotten

  --- @return table
  local function load_engine_cmds(opts)
    local H = harness(opts or {})
    forgotten = 0
    package.loaded["sandbox.engine_utils"] = {
      forget = function()
        forgotten = forgotten + 1
      end,
    }
    package.loaded["sandbox.util.project_config"] = {
      read_engine_override = function()
        return (opts or {}).sandboxrc, (opts or {}).sandboxrc_invalid or false
      end,
    }
    package.loaded["sandbox.bindings.usrcmds.engine_commands"] = nil
    H.mod = require("sandbox.bindings.usrcmds.engine_commands")
    return H
  end

  before_each(function()
    vim.g.sandbox_engine = nil
  end)

  after_each(function()
    vim.g.sandbox_engine = nil
    package.loaded["sandbox.util.project_config"] = nil
    cleanup()
  end)

  it("sets the session override for each valid engine", function()
    local H = load_engine_cmds()

    for _, name in ipairs({ "docker", "podman", "nerdctl" }) do
      H.mod.set(name)
      assert.are.equal(name, vim.g.sandbox_engine)
    end

    assert.are.equal(3, #H.notices)
  end)

  it("refuses anything else and leaves the override alone", function()
    local H = load_engine_cmds()
    vim.g.sandbox_engine = "docker"

    H.mod.set("containerd")

    assert.are.equal("docker", vim.g.sandbox_engine)
    assert.is_truthy(notice_of(H, "warn").msg:find("Usage:", 1, true))
  end)

  it("cycles in a fixed order, so the same key always lands in the same place", function()
    local H = load_engine_cmds()
    -- `resolve_engine_name` is stubbed to "docker" unless a session override
    -- is set, and `set` sets one -- so the cycle is observable end to end.
    package.loaded["sandbox"].resolve_engine_name = function()
      return vim.g.sandbox_engine or "docker"
    end

    assert.are.equal("podman", H.mod.cycle())
    assert.are.equal("nerdctl", H.mod.cycle())
    assert.are.equal("docker", H.mod.cycle())
  end)

  it("starts the cycle at the first entry when the current engine is unknown", function()
    local H = load_engine_cmds()
    package.loaded["sandbox"].resolve_engine_name = function()
      return "containerd"
    end

    assert.are.equal("podman", H.mod.cycle())
  end)

  it("clears the override and forgets the liveness probes", function()
    local H = load_engine_cmds()
    vim.g.sandbox_engine = "podman"

    H.mod.reset()

    assert.is_nil(vim.g.sandbox_engine)
    assert.are.equal(1, forgotten)
    assert.is_truthy(notice_of(H, "info").msg:find("Session engine override cleared", 1, true))
  end)

  it("names the session override as the source when one is set", function()
    local H = load_engine_cmds()
    vim.g.sandbox_engine = "podman"

    H.mod.get()

    assert.is_truthy(notice_of(H, "info").msg:find("session override", 1, true))
  end)

  it("names .sandboxrc as the source when that is what decided", function()
    local H = load_engine_cmds({ sandboxrc = "podman" })

    H.mod.get()

    assert.is_truthy(notice_of(H, "info").msg:find(".sandboxrc", 1, true))
  end)

  it("names the config as the source when nothing overrode it", function()
    local H = load_engine_cmds()

    H.mod.get()

    assert.is_truthy(notice_of(H, "info").msg:find("(config)", 1, true))
  end)

  -- ERR-10: an invalid .sandboxrc value must not be reported as if the file
  -- had nothing to say -- that is what "kein Argument" vs. "ungültiges
  -- Argument" was collapsed into before the fix.
  it("names the ignored invalid .sandboxrc value as the source, not the plain config", function()
    local H = load_engine_cmds({ sandboxrc_invalid = true })

    H.mod.get()

    local msg = notice_of(H, "info").msg
    assert.is_truthy(msg:find("invalid", 1, true), msg)
    assert.is_truthy(msg:find(".sandboxrc", 1, true), msg)
  end)
end)

describe("usrcmds devcontainer_commands", function()
  --- @param opts { path?: string|nil, config?: table|nil, parse_err?: string|nil, workspace?: string }
  --- @return table
  local function load_devcontainer(opts)
    local H = harness({})
    H.build_calls = {}
    package.loaded["sandbox.util.devcontainer_file"] = {
      find = function()
        return opts.path
      end,
      parse = function()
        return opts.config, opts.parse_err
      end,
      workspace_dir = function()
        return opts.workspace or "C:/Users/a b/My Project"
      end,
    }
    package.loaded["sandbox.core.usecases.devcontainer.build"] = function(...)
      H.build_calls[#H.build_calls + 1] = { ... }
    end
    H.exec_calls = {}
    package.loaded["sandbox.bindings.usrcmds.container_commands"] = {
      exec = function(...)
        H.exec_calls[#H.exec_calls + 1] = { ... }
      end,
    }
    package.loaded["sandbox.bindings.usrcmds.devcontainer_commands"] = nil
    H.mod = require("sandbox.bindings.usrcmds.devcontainer_commands")
    return H
  end

  after_each(cleanup)

  it("says what it looked for when there is no devcontainer.json", function()
    local H = load_devcontainer({ path = nil })

    H.mod.build()
    H.mod.attach()

    assert.are.equal(2, #H.notices)
    assert.is_truthy(notice_of(H, "warn").msg:find("No .devcontainer/devcontainer.json", 1, true))
    assert.are.same({}, H.build_calls)
  end)

  it("reports a parse error with the path it failed on", function()
    local H =
      load_devcontainer({ path = "/proj/.devcontainer/devcontainer.json", config = nil, parse_err = "bad JSON" })

    H.mod.build()

    local err = notice_of(H, "error")
    assert.is_truthy(err.msg:find("/proj/.devcontainer/devcontainer.json", 1, true))
    assert.is_truthy(err.msg:find("bad JSON", 1, true))
  end)

  it("derives a container name from the workspace, with unsafe characters replaced", function()
    local H = load_devcontainer({
      path = "/proj/.devcontainer/devcontainer.json",
      config = { image = "alpine" },
    })

    H.mod.build()

    local args = H.build_calls[1]
    -- engine, compose_engine, engine_name, config, workspace_dir, name, cb
    assert.are.equal("docker", args[3])
    assert.are.equal("C:/Users/a b/My Project", args[5])
    assert.are.equal("sandbox-devcontainer-My_Project", args[6])
    assert.is_function(args[7])
  end)

  it("keeps dots, dashes and underscores in the derived name", function()
    local H = load_devcontainer({
      path = "/proj/.devcontainer/devcontainer.json",
      config = { image = "alpine" },
      workspace = "/home/me/my-app_v1.2",
    })

    H.mod.build()

    assert.are.equal("sandbox-devcontainer-my-app_v1.2", H.build_calls[1][6])
  end)

  it("reports the build failure through friendly_error", function()
    local H = load_devcontainer({
      path = "/proj/.devcontainer/devcontainer.json",
      config = { image = "alpine" },
    })

    H.mod.build()
    H.build_calls[1][7](false, "Cannot connect to the Docker daemon")

    local err = notice_of(H, "error")
    assert.is_truthy(err.msg:find("Devcontainer build failed", 1, true))
    assert.is_truthy(err.msg:find("Docker daemon not reachable", 1, true))
  end)

  it("points at the attach command once the build succeeded", function()
    local H = load_devcontainer({
      path = "/proj/.devcontainer/devcontainer.json",
      config = { image = "alpine" },
    })

    H.mod.build()
    H.build_calls[1][7](true, "9f2c1d")

    local infos = {}
    for _, n in ipairs(H.notices) do
      if n.level == "info" then
        infos[#infos + 1] = n.msg
      end
    end
    assert.are.equal(2, #infos)
    assert.is_truthy(infos[2]:find(":Sandbox devcontainer attach", 1, true))
  end)

  it("attaches by exec'ing the name build would have given the container", function()
    local H = load_devcontainer({
      path = "/proj/.devcontainer/devcontainer.json",
      config = { image = "alpine" },
    })

    H.mod.attach()

    assert.are.same({ "sandbox-devcontainer-My_Project" }, H.exec_calls[1])
  end)

  it("refuses to guess a container for a compose-based devcontainer, and says what to do", function()
    local H = load_devcontainer({
      path = "/proj/.devcontainer/devcontainer.json",
      config = { dockerComposeFile = "compose.yml", service = "app" },
    })

    H.mod.attach()

    assert.are.same({}, H.exec_calls)
    assert.is_truthy(notice_of(H, "warn").msg:find(":Sandbox compose ps", 1, true))
  end)

  it("stops before building when no engine resolves", function()
    local H = load_devcontainer({
      path = "/proj/.devcontainer/devcontainer.json",
      config = { image = "alpine" },
    })
    package.loaded["sandbox"].get_engine = function()
      return nil
    end

    H.mod.build()

    assert.are.same({}, H.build_calls)
  end)

  describe("conflict preflight (gitsuite.nvim, optional)", function()
    it("builds normally when gitsuite.nvim is not installed -- fails open", function()
      local H = load_devcontainer({
        path = "/proj/.devcontainer/devcontainer.json",
        config = { image = "alpine" },
      })

      H.mod.build()

      assert.are.equal(1, #H.build_calls)
    end)

    it("builds once gitsuite.nvim reports no unresolved conflicts", function()
      local H = load_devcontainer({
        path = "/proj/.devcontainer/devcontainer.json",
        config = { image = "alpine" },
      })
      package.loaded["gitsuite.features.conflict"] = {
        list = function(on_done)
          on_done(0)
        end,
      }

      H.mod.build()

      assert.are.equal(1, #H.build_calls)
    end)

    it("aborts the build and never mounts the workspace when conflicts remain", function()
      local H = load_devcontainer({
        path = "/proj/.devcontainer/devcontainer.json",
        config = { image = "alpine" },
      })
      package.loaded["gitsuite.features.conflict"] = {
        list = function(on_done)
          on_done(2)
        end,
      }

      H.mod.build()

      assert.are.same({}, H.build_calls)
      local err = notice_of(H, "error")
      assert.is_truthy(err.msg:find("aborted", 1, true))
      assert.is_truthy(err.msg:find("2 files", 1, true))
    end)
  end)
end)

describe("usrcmds wsl_commands", function()
  --- @param opts { results?: table<string, any[]>, answer?: boolean|nil, wsl?: boolean }
  --- @return table
  local function load_wsl(opts)
    opts = opts or {}
    local H = harness(opts)
    package.loaded["sandbox.engine_utils"] = {
      is_executable = function(cmd)
        return cmd == "wsl" and opts.wsl ~= false
      end,
    }
    -- The WSL command module reaches for its own engine, not the container one.
    package.loaded["sandbox.adapters.wsl.engine"] = H.engine
    package.loaded["sandbox.bindings.usrcmds.wsl_commands"] = nil
    H.mod = require("sandbox.bindings.usrcmds.wsl_commands")
    return H
  end

  after_each(function()
    cleanup()
    vim.cmd("silent! %bwipeout!")
  end)

  it("is available exactly when wsl.exe is on PATH", function()
    assert.is_true(load_wsl({ wsl = true }).mod.available())
    assert.is_false(load_wsl({ wsl = false }).mod.available())
  end)

  local GUARDS = {
    { fn = "start", args = { "" } },
    { fn = "stop", args = { "" } },
    { fn = "set_default", args = { "" } },
    { fn = "set_version", args = { "", "2" } },
    { fn = "set_version", args = { "Ubuntu", "3" } },
    { fn = "set_version", args = { "Ubuntu", nil } },
    { fn = "exec", args = { "" } },
    { fn = "export", args = { "Ubuntu", "" } },
    { fn = "export", args = { "", "/tmp/u.tar" } },
    { fn = "import", args = { "Ubuntu", "/dir", "" } },
    { fn = "import", args = { "Ubuntu", "", "/tmp/u.tar" } },
    { fn = "import", args = { "", "/dir", "/tmp/u.tar" } },
  }

  for _, case in ipairs(GUARDS) do
    it(case.fn .. "(" .. vim.inspect(case.args):gsub("%s+", " ") .. ") warns without asking wsl", function()
      local H = load_wsl({})

      H.mod[case.fn](unpack(case.args, 1, 3))

      assert.is_truthy(notice_of(H, "warn").msg:find("Usage:", 1, true))
      assert.are.same({}, H.calls)
    end)
  end

  it("renders the distro list into a named scratch buffer, default marked", function()
    local H = load_wsl({
      results = {
        list_distros = {
          {
            { name = "Ubuntu-24.04", state = "Running", default = true },
            { name = "Debian", state = "Stopped", default = false },
          },
          nil,
        },
      },
    })

    H.mod.list()

    local buf = vim.api.nvim_get_current_buf()
    assert.are.equal("sandbox.nvim://wsl-list", vim.api.nvim_buf_get_name(buf))
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    assert.is_truthy(lines[1]:find("NAME", 1, true))
    assert.is_truthy(lines[3]:find("Ubuntu%-24%.04%s+Running%s+%*"))
    assert.is_truthy(lines[4]:find("Debian%s+Stopped%s*$"))
    assert.is_false(vim.bo[buf].modifiable)
  end)

  it("reports a failed listing instead of opening an empty buffer", function()
    local H = load_wsl({ results = { list_distros = { nil, "no distributions" } } })

    H.mod.list()

    assert.is_truthy(notice_of(H, "error").msg:find("Failed to list WSL distros", 1, true))
    assert.are_not.equal("sandbox.nvim://wsl-list", vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf()))
  end)

  local HAPPY = {
    { fn = "start", args = { "Ubuntu" }, method = "start_distro", says = "WSL distro started: Ubuntu" },
    { fn = "stop", args = { "Ubuntu" }, method = "stop_distro", says = "WSL distro terminated: Ubuntu" },
    {
      fn = "set_default",
      args = { "Ubuntu" },
      method = "set_default_distro",
      says = "Default WSL distro set to: Ubuntu",
    },
    {
      fn = "export",
      args = { "Ubuntu", "C:/backups/u.tar" },
      method = "export_distro",
      says = "WSL distro Ubuntu exported to C:/backups/u.tar",
    },
    {
      fn = "import",
      args = { "Restored", "D:/wsl/restored", "C:/backups/u.tar" },
      method = "import_distro",
      says = "WSL distro imported: Restored",
    },
  }

  for _, case in ipairs(HAPPY) do
    it(case.fn .. " forwards to " .. case.method .. " and confirms it", function()
      local H = load_wsl({})

      H.mod[case.fn](unpack(case.args, 1, 3))

      assert.are.equal(case.method, H.calls[1].method)
      assert.are.equal(case.says, notice_of(H, "info").msg)
    end)

    it(case.fn .. " reports a failure with the raw text as context", function()
      local H = load_wsl({ results = { [case.method] = { false, "There is no distribution with that name." } } })

      H.mod[case.fn](unpack(case.args, 1, 3))

      local err = notice_of(H, "error")
      assert.is_truthy(err.msg:find("There is no distribution", 1, true))
      assert.are.equal("There is no distribution with that name.", err.ctx.err)
    end)
  end

  it("turns the version string into the number the adapter expects", function()
    local H = load_wsl({})

    H.mod.set_version("Ubuntu", "1")

    assert.are.equal(1, H.calls[1].args[2])
    assert.is_truthy(notice_of(H, "info").msg:find("set to version 1", 1, true))
  end)

  it("passes an empty exec command as nil", function()
    local H = load_wsl({})

    H.mod.exec("Ubuntu", {})

    assert.is_nil(H.calls[1].args[2])
  end)

  it("keeps an exec command tail intact", function()
    local H = load_wsl({})

    H.mod.exec("Ubuntu", { "ls", "-la" })

    assert.are.same({ "ls", "-la" }, H.calls[1].args[2])
  end)

  it("reports an exec that raises instead of letting it escape the command", function()
    local H = load_wsl({})
    package.loaded["sandbox.adapters.wsl.engine"] = {
      exec_in_distro = function()
        error("exec_in_distro not implemented.")
      end,
    }

    assert.has_no.errors(function()
      H.mod.exec("Ubuntu")
    end)
    assert.is_truthy(notice_of(H, "error").msg:find("Failed to exec in WSL distro Ubuntu", 1, true))
  end)

  it("asks before shutting the whole VM down", function()
    local H = load_wsl({ answer = false })

    H.mod.shutdown_all()

    assert.are.same({ "Shut down WSL and all running distros?" }, H.confirms)
    assert.are.same({}, H.calls)
  end)

  it("shuts down on a yes and says so", function()
    local H = load_wsl({})

    H.mod.shutdown_all()

    assert.are.equal("shutdown_all", H.calls[1].method)
    assert.are.equal("WSL shut down", notice_of(H, "info").msg)
  end)
end)
