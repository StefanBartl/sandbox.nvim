-- The argv every adapter method *would* have spawned, for all three
-- container engines, asserted at the seam instead of at a real daemon.
--
-- Why a matrix rather than one representative per family: `engine_parity_spec`
-- proves docker/podman/nerdctl expose the same method *names*, and
-- `long_running_spec` proves one member of each family reaches `run_argv` --
-- neither looks at what the other two engines put in the argv. Podman is not
-- a rename of docker: `podman stop` takes `--timeout 1` where docker takes
-- `--time=1`, and `podman ps`/`podman images` want `--format json` where
-- docker wants a Go template. Exactly those four are the cases a
-- name-level parity check cannot see, and each of them fails at runtime
-- against the real CLI, on the user's machine, not here.
--
-- Three seams are stubbed, because the adapters use three different spawn
-- mechanisms:
--
--   * `sandbox.util.run_argv`        -- faked via package.preload (most)
--   * `vim.fn.jobstart`             -- the fire-and-forget mutations
--   * `vim.system`                  -- `follow_logs` only
--
-- The fake must be installed *before* the modules are required: every leaf
-- adapter binds `run_argv` to an upvalue at load time, and the aggregators
-- copy the leaf functions into a table at load time too, so a fake installed
-- afterwards would never be seen (hence `reload_prefix`).
--
-- Nothing here asserts quoting, because there is nothing to quote: these are
-- argv lists, not shell strings. That is the property under test -- a path
-- with a space has to survive as ONE element, and no adapter may add quotes
-- of its own "to be safe", which a shell-less spawn would then pass through
-- to the engine verbatim.
---@diagnostic disable: need-check-nil
local fake_run_argv = require("TESTS.sandbox.helpers.fake_run_argv")

local ENGINES = { "docker", "podman", "nerdctl" }

-- One awkward path, reused everywhere a path is taken: a space, a Windows
-- drive letter and a colon that a `:`-split would eat.
local SPACED = "C:/Users/a b/backup archive.tar"

local function noop() end

--- @param expected string[]
--- @param actual string[]|nil
--- @param label string
local function assert_argv(expected, actual, label)
  assert.is_not_nil(actual, label .. ": nothing was spawned")
  for i, v in ipairs(actual) do
    assert.are.equal("string", type(v), label .. ": argv[" .. i .. "] is not a string")
  end
  assert.are.same(expected, actual, label)
end

--- Every case: which seam it spawns through, how to call it through the
--- engine aggregator, and the argv it must produce for engine `e`.
--- @type { name: string, seam: string, call: fun(api: table), argv: fun(e: string): string[], input?: string }[]
local CASES = {
  -- ── containers: blocking, through run_argv ────────────────────────────
  {
    name = "cp_container",
    seam = "run_argv",
    call = function(api)
      api.engine.cp_container(SPACED, "abc123:/app/backup archive.tar")
    end,
    argv = function(e)
      return { e, "cp", SPACED, "abc123:/app/backup archive.tar" }
    end,
  },
  {
    name = "get_logs",
    seam = "run_argv",
    call = function(api)
      api.engine.get_logs("abc123")
    end,
    argv = function(e)
      return { e, "logs", "abc123" }
    end,
  },
  {
    name = "inspect_container",
    seam = "run_argv",
    call = function(api)
      api.engine.inspect_container("abc123")
    end,
    argv = function(e)
      return { e, "inspect", "abc123" }
    end,
  },
  {
    name = "list_containers",
    seam = "run_argv",
    call = function(api)
      api.engine.list_containers()
    end,
    argv = function(e)
      -- Podman's `ps` emits one JSON array; docker/nerdctl emit one object
      -- per line from a Go template. The adapters parse accordingly, so the
      -- flag and the parser have to stay in step.
      local format = e == "podman" and "json" or "{{json .}}"
      return { e, "ps", "-a", "--format", format }
    end,
  },
  {
    name = "rename_container",
    seam = "run_argv",
    call = function(api)
      api.engine.rename_container("abc123", "web 2")
    end,
    argv = function(e)
      return { e, "rename", "abc123", "web 2" }
    end,
  },
  {
    name = "start_container",
    seam = "run_argv",
    call = function(api)
      api.engine.start_container("abc123")
    end,
    argv = function(e)
      return { e, "start", "abc123" }
    end,
  },
  {
    name = "stats_container",
    seam = "run_argv",
    call = function(api)
      api.engine.stats_container("abc123")
    end,
    argv = function(e)
      return { e, "stats", "--no-stream", "abc123" }
    end,
  },
  {
    name = "top_container",
    seam = "run_argv",
    call = function(api)
      api.engine.top_container("abc123")
    end,
    argv = function(e)
      return { e, "top", "abc123" }
    end,
  },
  {
    name = "prune_containers",
    seam = "run_argv",
    call = function(api)
      api.engine.prune_containers(noop)
    end,
    argv = function(e)
      return { e, "container", "prune", "-f" }
    end,
  },

  -- ── containers: fire-and-forget, through vim.fn.jobstart ──────────────
  {
    name = "kill_container",
    seam = "jobstart",
    call = function(api)
      api.engine.kill_container("abc123")
    end,
    argv = function(e)
      return { e, "kill", "abc123" }
    end,
  },
  {
    name = "pause_container",
    seam = "jobstart",
    call = function(api)
      api.engine.pause_container("abc123")
    end,
    argv = function(e)
      return { e, "pause", "abc123" }
    end,
  },
  {
    name = "unpause_container",
    seam = "jobstart",
    call = function(api)
      api.engine.unpause_container("abc123")
    end,
    argv = function(e)
      return { e, "unpause", "abc123" }
    end,
  },
  {
    name = "remove_container",
    seam = "jobstart",
    call = function(api)
      api.engine.remove_container("abc123")
    end,
    argv = function(e)
      return { e, "rm", "abc123" }
    end,
  },
  {
    name = "restart_container",
    seam = "jobstart",
    call = function(api)
      api.engine.restart_container("abc123")
    end,
    argv = function(e)
      return { e, "restart", "abc123" }
    end,
  },
  {
    name = "stop_container",
    seam = "jobstart",
    call = function(api)
      api.engine.stop_container("abc123")
    end,
    argv = function(e)
      -- podman's `stop` has no `--time=`; it spells the same thing
      -- `--timeout <n>` as two argv elements.
      if e == "podman" then
        return { e, "stop", "--timeout", "1", "abc123" }
      end
      return { e, "stop", "--time=1", "abc123" }
    end,
  },
  {
    name = "run_container (every option)",
    seam = "jobstart",
    call = function(api)
      api.engine.run_container({
        image = "nginx:1.27",
        name = "my web",
        ports = { "8080:80", "8443:443" },
        volumes = { SPACED .. ":/data" },
        env = { "TZ=Europe/Vienna", "MSG=hello world" },
        command = { "nginx", "-g", "daemon off;" },
      })
    end,
    argv = function(e)
      return {
        e,
        "run",
        "-d",
        "--name",
        "my web",
        "-p",
        "8080:80",
        "-p",
        "8443:443",
        "-v",
        SPACED .. ":/data",
        "-e",
        "TZ=Europe/Vienna",
        "-e",
        "MSG=hello world",
        "nginx:1.27",
        "nginx",
        "-g",
        "daemon off;",
      }
    end,
  },
  {
    name = "run_container (image only)",
    seam = "jobstart",
    call = function(api)
      api.engine.run_container({ image = "alpine" })
    end,
    argv = function(e)
      return { e, "run", "-d", "alpine" }
    end,
  },
  {
    name = "run_container (empty name is no name)",
    seam = "jobstart",
    call = function(api)
      api.engine.run_container({ image = "alpine", name = "" })
    end,
    argv = function(e)
      return { e, "run", "-d", "alpine" }
    end,
  },

  -- ── images ────────────────────────────────────────────────────────────
  {
    name = "history_image",
    seam = "run_argv",
    call = function(api)
      api.engine.history_image("nginx:latest")
    end,
    argv = function(e)
      return { e, "history", "nginx:latest" }
    end,
  },
  {
    name = "inspect_image",
    seam = "run_argv",
    call = function(api)
      api.engine.inspect_image("nginx:latest")
    end,
    argv = function(e)
      return { e, "inspect", "nginx:latest" }
    end,
  },
  {
    name = "list_images",
    seam = "run_argv",
    call = function(api)
      api.engine.list_images()
    end,
    argv = function(e)
      local format = e == "podman" and "json" or "{{json .}}"
      return { e, "images", "--format", format }
    end,
  },
  {
    name = "load_image",
    seam = "run_argv",
    call = function(api)
      api.engine.load_image(SPACED)
    end,
    argv = function(e)
      return { e, "load", "-i", SPACED }
    end,
  },
  {
    name = "save_image",
    seam = "run_argv",
    call = function(api)
      api.engine.save_image("nginx:latest", SPACED)
    end,
    argv = function(e)
      -- `-o <path>` comes before the image, not after it.
      return { e, "save", "-o", SPACED, "nginx:latest" }
    end,
  },
  {
    name = "tag_image",
    seam = "run_argv",
    call = function(api)
      api.engine.tag_image("nginx:latest", "registry.example.com:5000/nginx:pinned")
    end,
    argv = function(e)
      return { e, "tag", "nginx:latest", "registry.example.com:5000/nginx:pinned" }
    end,
  },
  {
    name = "pull_image",
    seam = "run_argv",
    call = function(api)
      api.engine.pull_image("registry.example.com:5000/nginx:pinned", noop)
    end,
    argv = function(e)
      return { e, "pull", "registry.example.com:5000/nginx:pinned" }
    end,
  },
  {
    name = "push_image",
    seam = "run_argv",
    call = function(api)
      api.engine.push_image("registry.example.com:5000/nginx:pinned", noop)
    end,
    argv = function(e)
      return { e, "push", "registry.example.com:5000/nginx:pinned" }
    end,
  },
  {
    name = "prune_images",
    seam = "run_argv",
    call = function(api)
      api.engine.prune_images(noop)
    end,
    argv = function(e)
      return { e, "image", "prune", "-f" }
    end,
  },
  {
    name = "remove_image",
    seam = "jobstart",
    call = function(api)
      api.engine.remove_image("sha256:deadbeef")
    end,
    argv = function(e)
      return { e, "rmi", "sha256:deadbeef" }
    end,
  },

  -- ── networks ──────────────────────────────────────────────────────────
  {
    name = "list_networks",
    seam = "run_argv",
    call = function(api)
      api.engine.list_networks()
    end,
    argv = function(e)
      return { e, "network", "ls", "--format", "{{json .}}" }
    end,
  },
  {
    name = "create_network",
    seam = "run_argv",
    call = function(api)
      api.engine.create_network("my net")
    end,
    argv = function(e)
      return { e, "network", "create", "my net" }
    end,
  },
  {
    name = "inspect_network",
    seam = "run_argv",
    call = function(api)
      api.engine.inspect_network("bridge")
    end,
    argv = function(e)
      return { e, "network", "inspect", "bridge" }
    end,
  },
  {
    name = "connect_network",
    seam = "run_argv",
    call = function(api)
      api.engine.connect_network("bridge", "abc123")
    end,
    argv = function(e)
      return { e, "network", "connect", "bridge", "abc123" }
    end,
  },
  {
    name = "disconnect_network",
    seam = "run_argv",
    call = function(api)
      api.engine.disconnect_network("bridge", "abc123")
    end,
    argv = function(e)
      return { e, "network", "disconnect", "bridge", "abc123" }
    end,
  },
  {
    name = "prune_networks",
    seam = "run_argv",
    call = function(api)
      api.engine.prune_networks(noop)
    end,
    argv = function(e)
      return { e, "network", "prune", "-f" }
    end,
  },
  {
    name = "remove_network",
    seam = "jobstart",
    call = function(api)
      api.engine.remove_network("my net")
    end,
    argv = function(e)
      return { e, "network", "rm", "my net" }
    end,
  },

  -- ── volumes ───────────────────────────────────────────────────────────
  {
    name = "list_volumes",
    seam = "run_argv",
    call = function(api)
      api.engine.list_volumes()
    end,
    argv = function(e)
      return { e, "volume", "ls", "--format", "{{json .}}" }
    end,
  },
  {
    name = "create_volume",
    seam = "run_argv",
    call = function(api)
      api.engine.create_volume("my vol")
    end,
    argv = function(e)
      return { e, "volume", "create", "my vol" }
    end,
  },
  {
    name = "inspect_volume",
    seam = "run_argv",
    call = function(api)
      api.engine.inspect_volume("my vol")
    end,
    argv = function(e)
      return { e, "volume", "inspect", "my vol" }
    end,
  },
  {
    name = "prune_volumes",
    seam = "run_argv",
    call = function(api)
      api.engine.prune_volumes(noop)
    end,
    argv = function(e)
      return { e, "volume", "prune", "-f" }
    end,
  },
  {
    name = "remove_volume",
    seam = "jobstart",
    call = function(api)
      api.engine.remove_volume("my vol")
    end,
    argv = function(e)
      return { e, "volume", "rm", "my vol" }
    end,
  },

  -- ── registry ──────────────────────────────────────────────────────────
  {
    name = "login_registry (with registry)",
    seam = "run_argv",
    call = function(api)
      api.engine.login_registry("alice", "s3cret", "registry.example.com:5000")
    end,
    argv = function(e)
      return { e, "login", "--username", "alice", "--password-stdin", "registry.example.com:5000" }
    end,
    input = "s3cret",
  },
  {
    name = "logout_registry (without registry)",
    seam = "run_argv",
    call = function(api)
      api.engine.logout_registry()
    end,
    argv = function(e)
      return { e, "logout" }
    end,
  },

  -- ── compose ───────────────────────────────────────────────────────────
  {
    name = "compose up",
    seam = "run_argv",
    call = function(api)
      api.compose.up("C:/my project/compose.yml", noop)
    end,
    argv = function(e)
      return { e, "compose", "-f", "C:/my project/compose.yml", "up", "-d" }
    end,
  },
  {
    name = "compose down",
    seam = "run_argv",
    call = function(api)
      api.compose.down("C:/my project/compose.yml", noop)
    end,
    argv = function(e)
      return { e, "compose", "-f", "C:/my project/compose.yml", "down" }
    end,
  },
  {
    name = "compose restart",
    seam = "run_argv",
    call = function(api)
      api.compose.restart("C:/my project/compose.yml", noop)
    end,
    argv = function(e)
      return { e, "compose", "-f", "C:/my project/compose.yml", "restart" }
    end,
  },
  {
    name = "compose ps",
    seam = "run_argv",
    call = function(api)
      api.compose.ps("C:/my project/compose.yml")
    end,
    argv = function(e)
      return { e, "compose", "-f", "C:/my project/compose.yml", "ps" }
    end,
  },
  {
    name = "compose logs",
    seam = "run_argv",
    call = function(api)
      api.compose.logs("C:/my project/compose.yml")
    end,
    argv = function(e)
      return { e, "compose", "-f", "C:/my project/compose.yml", "logs" }
    end,
  },

  -- ── follow_logs: vim.system, not run_argv ─────────────────────────────
  {
    name = "follow_logs",
    seam = "system",
    call = function(api)
      api.engine.follow_logs("abc123", noop)
    end,
    argv = function(e)
      return { e, "logs", "-f", "abc123" }
    end,
  },
}

for _, engine_name in ipairs(ENGINES) do
  describe("adapters." .. engine_name .. " argv", function()
    local run_state, jobstart_argv, system_argv
    local real_jobstart, real_system

    before_each(function()
      run_state = fake_run_argv.install({ ok = true, output = "[]" })
      jobstart_argv, system_argv = nil, nil

      real_jobstart, real_system = vim.fn.jobstart, vim.system

      ---@diagnostic disable-next-line: duplicate-set-field
      vim.fn.jobstart = function(argv, _opts)
        jobstart_argv = argv
        -- Deliberately no on_exit here: this spec is about the argv, and the
        -- callback contracts have their own spec (adapters/callbacks_spec).
        return 1
      end
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.system = function(argv, _opts, _on_exit)
        system_argv = argv
        return { kill = function() end }
      end

      -- Purge the whole adapter subtree, not just the leaf: the aggregators
      -- copy leaf functions into a table at load time.
      fake_run_argv.reload_prefix("sandbox.adapters." .. engine_name .. ".")
    end)

    after_each(function()
      vim.fn.jobstart, vim.system = real_jobstart, real_system
      fake_run_argv.reset()
    end)

    for _, case in ipairs(CASES) do
      it(engine_name .. ": " .. case.name, function()
        local api = {
          engine = require("sandbox.adapters." .. engine_name .. ".engine"),
          compose = require("sandbox.adapters." .. engine_name .. ".compose_engine"),
        }

        case.call(api)

        local expected = case.argv(engine_name)
        if case.seam == "jobstart" then
          assert_argv(expected, jobstart_argv, case.name)
          assert.are.equal(0, #run_state.calls, case.name .. " must not also go through run_argv")
        elseif case.seam == "system" then
          assert_argv(expected, system_argv, case.name)
        else
          assert.are.equal(1, #run_state.calls, case.name .. ": expected exactly one run_argv call")
          assert_argv(expected, run_state.calls[1].cmd, case.name)
          assert.are.equal(case.input, run_state.calls[1].input, case.name .. ": stdin")
        end
      end)
    end

    it(engine_name .. ": no adapter ever puts a password in argv", function()
      local api = { engine = require("sandbox.adapters." .. engine_name .. ".engine") }
      api.engine.login_registry("alice", "s3cret", "registry.example.com")

      for _, element in ipairs(run_state.calls[1].cmd) do
        assert.are_not.equal("s3cret", element)
      end
      assert.are.equal("s3cret", run_state.calls[1].input)
    end)

    it(engine_name .. ": follow_logs' handle kills the process it started", function()
      local killed
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.system = function(_argv, _opts, _on_exit)
        return {
          kill = function(_, signal)
            killed = signal
          end,
        }
      end

      local engine = require("sandbox.adapters." .. engine_name .. ".engine")
      local handle = engine.follow_logs("abc123", noop)
      handle.stop()

      assert.are.equal("sigterm", killed)
    end)
  end)
end

describe("adapters.wsl argv", function()
  local state

  before_each(function()
    state = fake_run_argv.install({ ok = true, output = "" })
    fake_run_argv.reload_prefix("sandbox.adapters.wsl.")
  end)

  after_each(function()
    fake_run_argv.reset()
  end)

  local WSL_CASES = {
    {
      name = "list_distros",
      call = function(E)
        E.list_distros()
      end,
      argv = { "wsl", "--list", "--verbose" },
    },
    {
      name = "start_distro (no `start` verb exists; a no-op command is the trigger)",
      call = function(E)
        E.start_distro("Ubuntu 24.04")
      end,
      argv = { "wsl", "-d", "Ubuntu 24.04", "--", "echo" },
    },
    {
      name = "stop_distro",
      call = function(E)
        E.stop_distro("Ubuntu 24.04")
      end,
      argv = { "wsl", "--terminate", "Ubuntu 24.04" },
    },
    {
      name = "set_default_distro",
      call = function(E)
        E.set_default_distro("Ubuntu 24.04")
      end,
      argv = { "wsl", "--set-default", "Ubuntu 24.04" },
    },
    {
      name = "set_version_distro stringifies the version number",
      call = function(E)
        E.set_version_distro("Ubuntu 24.04", 2)
      end,
      argv = { "wsl", "--set-version", "Ubuntu 24.04", "2" },
    },
    {
      name = "export_distro",
      call = function(E)
        E.export_distro("Ubuntu 24.04", SPACED)
      end,
      argv = { "wsl", "--export", "Ubuntu 24.04", SPACED },
    },
    {
      name = "import_distro",
      call = function(E)
        E.import_distro("Restored 24.04", "D:/wsl distros/restored", SPACED)
      end,
      argv = { "wsl", "--import", "Restored 24.04", "D:/wsl distros/restored", SPACED },
    },
    {
      name = "shutdown_all (the VM, not one distro)",
      call = function(E)
        E.shutdown_all()
      end,
      argv = { "wsl", "--shutdown" },
    },
  }

  for _, case in ipairs(WSL_CASES) do
    it("wsl: " .. case.name, function()
      local E = require("sandbox.adapters.wsl.engine")
      case.call(E)
      assert.are.equal(1, #state.calls, case.name)
      assert_argv(case.argv, state.calls[1].cmd, case.name)
    end)
  end

  it("wsl: exec_in_distro puts `--` between the distro and the command", function()
    local captured
    local real_jobstart, real_termopen, real_cmd, real_feedkeys, real_set_buf =
      vim.fn.jobstart, vim.fn.termopen, vim.cmd, vim.api.nvim_feedkeys, vim.api.nvim_set_current_buf
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.fn.jobstart = function(argv)
      captured = argv
      return 0
    end
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.fn.termopen = function(argv)
      captured = argv
      return 0
    end
    vim.cmd = function(...) end
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.api.nvim_feedkeys = function(...) end
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.api.nvim_set_current_buf = function(...) end

    local E = require("sandbox.adapters.wsl.engine")
    E.exec_in_distro("Ubuntu 24.04", { "ls", "-la", "/mnt/c/Program Files" })

    vim.fn.jobstart, vim.fn.termopen, vim.cmd, vim.api.nvim_feedkeys, vim.api.nvim_set_current_buf =
      real_jobstart, real_termopen, real_cmd, real_feedkeys, real_set_buf

    assert_argv({ "wsl", "-d", "Ubuntu 24.04", "--", "ls", "-la", "/mnt/c/Program Files" }, captured, "exec_in_distro")
  end)

  it("wsl: exec_in_distro without a command drops into the login shell", function()
    local captured
    local real_jobstart, real_termopen, real_cmd, real_feedkeys, real_set_buf =
      vim.fn.jobstart, vim.fn.termopen, vim.cmd, vim.api.nvim_feedkeys, vim.api.nvim_set_current_buf
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.fn.jobstart = function(argv)
      captured = argv
      return 0
    end
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.fn.termopen = function(argv)
      captured = argv
      return 0
    end
    vim.cmd = function(...) end
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.api.nvim_feedkeys = function(...) end
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.api.nvim_set_current_buf = function(...) end

    local E = require("sandbox.adapters.wsl.engine")
    E.exec_in_distro("Ubuntu 24.04", {})

    vim.fn.jobstart, vim.fn.termopen, vim.cmd, vim.api.nvim_feedkeys, vim.api.nvim_set_current_buf =
      real_jobstart, real_termopen, real_cmd, real_feedkeys, real_set_buf

    assert_argv({ "wsl", "-d", "Ubuntu 24.04" }, captured, "exec_in_distro")
  end)
end)
