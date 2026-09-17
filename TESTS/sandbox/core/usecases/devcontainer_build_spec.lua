-- `core.usecases.devcontainer.build` is the only use case that is not a
-- one-line delegation: it picks one of three strategies out of a parsed
-- devcontainer.json, builds a `build` argv itself, and assembles the
-- `run_container` options (workspace mount, forwarded ports, env, the
-- keep-alive command) that everything afterwards depends on.
--
-- Nothing is built or pulled here. The `run_argv` seam is faked before the
-- module is required -- it binds the runner to an upvalue at load time, like
-- every adapter -- and the engines are recording doubles, so what is asserted
-- is the argv and the option table that *would* have been handed to an
-- engine.
---@diagnostic disable: need-check-nil
local fake_run_argv = require("TESTS.sandbox.helpers.fake_run_argv")

local WORKSPACE = "C:/Users/a b/my project"

--- A recording container-engine double.
--- @return table engine, table log
local function fake_engine()
  local log = {}
  local engine = {
    run_container = function(opts, on_done)
      log.run_container = opts
      log.run_done = on_done
      if log.run_result ~= nil then
        on_done(log.run_result, log.run_id)
      end
    end,
    pull_image = function(name, on_done)
      log.pulled = name
      if log.pull_ok ~= nil then
        on_done(log.pull_ok, log.pull_err)
      end
    end,
  }
  return engine, log
end

--- A recording compose-engine double.
--- @return table engine, table log
local function fake_compose()
  local log = {}
  local engine = {
    up = function(file, on_done)
      log.up_file = file
      log.up_done = on_done
    end,
  }
  return engine, log
end

--- @param opts table run_argv fake options
--- @return function usecase, table run_state
local function load_usecase(opts)
  local state = fake_run_argv.install(opts or { ok = true, output = "" })
  fake_run_argv.reload({ "sandbox.core.usecases.devcontainer.build" })
  return require("sandbox.core.usecases.devcontainer.build"), state
end

describe("core.usecases.devcontainer.build", function()
  after_each(function()
    fake_run_argv.reset()
  end)

  describe("dockerComposeFile", function()
    it("delegates to the compose engine and never touches the container engine", function()
      local build = load_usecase()
      local engine, engine_log = fake_engine()
      local compose, compose_log = fake_compose()

      build(
        engine,
        compose,
        "docker",
        { dockerComposeFile = "docker-compose.yml", service = "app" },
        WORKSPACE,
        "c",
        function() end
      )

      assert.are.equal(WORKSPACE .. "/.devcontainer/docker-compose.yml", compose_log.up_file)
      assert.is_nil(engine_log.run_container)
      assert.is_nil(engine_log.pulled)
    end)

    it("takes the first file when the key is a list", function()
      local build = load_usecase()
      local engine = fake_engine()
      local compose, compose_log = fake_compose()

      build(
        engine,
        compose,
        "podman",
        { dockerComposeFile = { "base.yml", "override.yml" } },
        WORKSPACE,
        "c",
        function() end
      )

      assert.are.equal(WORKSPACE .. "/.devcontainer/base.yml", compose_log.up_file)
    end)

    it("hands the caller's callback straight to compose up", function()
      local build = load_usecase()
      local engine = fake_engine()
      local compose, compose_log = fake_compose()
      local function cb() end

      build(engine, compose, "docker", { dockerComposeFile = "compose.yml" }, WORKSPACE, "c", cb)

      assert.are.equal(cb, compose_log.up_done)
    end)
  end)

  describe("build.dockerfile", function()
    it("builds `<engine> build -f <context>/<dockerfile> -t <name> <context>`", function()
      local build, run_state = load_usecase()
      local engine = fake_engine()
      local compose = fake_compose()

      build(
        engine,
        compose,
        "nerdctl",
        { build = { dockerfile = "Dockerfile" } },
        WORKSPACE,
        "sandbox-devcontainer-my_project",
        function() end
      )

      assert.are.equal(1, #run_state.calls)
      assert.are.same({
        "nerdctl",
        "build",
        "-f",
        WORKSPACE .. "/.devcontainer/./Dockerfile",
        "-t",
        "sandbox-devcontainer-my_project",
        WORKSPACE .. "/.devcontainer/.",
      }, run_state.calls[1].cmd)
    end)

    it("honours an explicit build.context", function()
      local build, run_state = load_usecase()
      local engine = fake_engine()
      local compose = fake_compose()

      build(
        engine,
        compose,
        "docker",
        { build = { dockerfile = "Containerfile", context = "sub dir" } },
        WORKSPACE,
        "c",
        function() end
      )

      assert.are.same({
        "docker",
        "build",
        "-f",
        WORKSPACE .. "/.devcontainer/sub dir/Containerfile",
        "-t",
        "c",
        WORKSPACE .. "/.devcontainer/sub dir",
      }, run_state.calls[1].cmd)
    end)

    it("reports the build output and starts nothing when the build fails", function()
      local build = load_usecase({ ok = false, output = "failed to solve: dockerfile parse error", code = 1 })
      local engine, engine_log = fake_engine()
      local compose = fake_compose()

      local ok, err
      build(engine, compose, "docker", { build = { dockerfile = "Dockerfile" } }, WORKSPACE, "c", function(o, e)
        ok, err = o, e
      end)

      assert.is_false(ok)
      assert.are.equal("failed to solve: dockerfile parse error", err)
      assert.is_nil(engine_log.run_container)
    end)

    it("runs the tag it just built, not the image key", function()
      local build = load_usecase({ ok = true, output = "" })
      local engine, engine_log = fake_engine()
      local compose = fake_compose()

      build(
        engine,
        compose,
        "docker",
        { build = { dockerfile = "Dockerfile" }, image = "ignored:latest" },
        WORKSPACE,
        "sandbox-devcontainer-x",
        function() end
      )

      assert.are.equal("sandbox-devcontainer-x", engine_log.run_container.image)
      assert.is_nil(engine_log.pulled)
    end)
  end)

  describe("image", function()
    it("pulls first, then runs the pulled image", function()
      local build = load_usecase()
      local engine, engine_log = fake_engine()
      local compose = fake_compose()
      engine_log.pull_ok = true

      build(
        engine,
        compose,
        "docker",
        { image = "mcr.microsoft.com/devcontainers/base:ubuntu" },
        WORKSPACE,
        "c",
        function() end
      )

      assert.are.equal("mcr.microsoft.com/devcontainers/base:ubuntu", engine_log.pulled)
      assert.are.equal("mcr.microsoft.com/devcontainers/base:ubuntu", engine_log.run_container.image)
    end)

    it("reports the pull error and starts nothing", function()
      local build = load_usecase()
      local engine, engine_log = fake_engine()
      local compose = fake_compose()
      engine_log.pull_ok = false
      engine_log.pull_err = "manifest unknown"

      local ok, err
      build(engine, compose, "docker", { image = "nope:latest" }, WORKSPACE, "c", function(o, e)
        ok, err = o, e
      end)

      assert.is_false(ok)
      assert.are.equal("manifest unknown", err)
      assert.is_nil(engine_log.run_container)
    end)
  end)

  it("says what is missing when the file declares no strategy at all", function()
    local build = load_usecase()
    local engine, engine_log = fake_engine()
    local compose, compose_log = fake_compose()

    local ok, err
    build(engine, compose, "docker", { name = "just a name" }, WORKSPACE, "c", function(o, e)
      ok, err = o, e
    end)

    assert.is_false(ok)
    assert.are.equal("devcontainer.json has none of image, build.dockerfile, or dockerComposeFile", err)
    assert.is_nil(engine_log.pulled)
    assert.is_nil(compose_log.up_file)
  end)

  describe("the run_container options", function()
    --- @param config table
    --- @return table opts
    local function run_opts_for(config)
      local build = load_usecase()
      local engine, engine_log = fake_engine()
      local compose = fake_compose()
      engine_log.pull_ok = true
      config.image = config.image or "alpine"
      build(engine, compose, "docker", config, WORKSPACE, "sandbox-devcontainer-my_project", function() end)
      return engine_log.run_container
    end

    it("mounts the workspace at the default /workspaces/<basename>", function()
      local opts = run_opts_for({})

      assert.are.same({ WORKSPACE .. ":/workspaces/my project" }, opts.volumes)
    end)

    it("honours an explicit workspaceFolder", function()
      local opts = run_opts_for({ workspaceFolder = "/srv/app" })

      assert.are.same({ WORKSPACE .. ":/srv/app" }, opts.volumes)
    end)

    it("keeps the container alive, since a devcontainer image often has no long-running CMD", function()
      local opts = run_opts_for({})

      assert.are.same({ "sleep", "infinity" }, opts.command)
      assert.are.equal("sandbox-devcontainer-my_project", opts.name)
    end)

    it("forwards each port to the identical host port, as a string", function()
      local opts = run_opts_for({ forwardPorts = { 3000, "5432" } })

      assert.are.same({ "3000:3000", "5432:5432" }, opts.ports)
    end)

    it("turns containerEnv into KEY=value pairs", function()
      -- One key only: `containerEnv` is a map, so with several the emitted
      -- order follows `pairs` and is not reproducible. Anything that ever
      -- wants to *diff* this argv has to sort it first.
      local opts = run_opts_for({ containerEnv = { TZ = "Europe/Vienna" } })

      assert.are.same({ "TZ=Europe/Vienna" }, opts.env)
    end)

    it("stringifies a non-string env value rather than concatenating nil", function()
      local opts = run_opts_for({ containerEnv = { DEBUG = 1 } })

      assert.are.same({ "DEBUG=1" }, opts.env)
    end)

    it("defaults ports and env to empty lists when the file names neither", function()
      local opts = run_opts_for({})

      assert.are.same({}, opts.ports)
      assert.are.same({}, opts.env)
    end)
  end)
end)
