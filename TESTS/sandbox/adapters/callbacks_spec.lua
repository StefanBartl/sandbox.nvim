-- What the adapters hand back once the process they started is gone: the
-- success value, the failure value, and what fills in for stderr when the
-- command failed without writing any.
--
-- `argv_matrix_spec` pins what would have been spawned; this pins what
-- happens afterwards. Both halves matter separately -- an adapter can build
-- a perfect argv and still report a failed `rm` as a success.
--
-- Docker is the representative engine here, deliberately. The three adapter
-- families differ only in argv (which `argv_matrix_spec` checks per engine);
-- their callback bodies are byte-identical, so running the same eight
-- callback cases three times would buy nothing but runtime. The two places
-- where podman really does differ -- `stop`'s flag spelling and the `ps`/
-- `images` output format -- are covered where they live, in
-- `argv_matrix_spec` and `parsing_spec`.
---@diagnostic disable: need-check-nil
local fake_run_argv = require("TESTS.sandbox.helpers.fake_run_argv")

--- Run `fn` and wait for a `vim.schedule`d callback to have landed.
--- @param fn fun()
--- @param is_done fun(): boolean
local function run_and_settle(fn, is_done)
  fn()
  vim.wait(500, is_done)
end

describe("adapters.docker: jobstart mutations report exit codes", function()
  local exit_code
  local real_jobstart

  before_each(function()
    real_jobstart = vim.fn.jobstart
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.fn.jobstart = function(_argv, opts)
      if opts and opts.on_exit then
        opts.on_exit(1, exit_code, "exit")
      end
      return 1
    end
    fake_run_argv.reload_prefix("sandbox.adapters.docker.")
  end)

  after_each(function()
    vim.fn.jobstart = real_jobstart
  end)

  local CASES = {
    {
      name = "kill_container",
      call = function(E, cb)
        E.kill_container("abc123", cb)
      end,
    },
    {
      name = "pause_container",
      call = function(E, cb)
        E.pause_container("abc123", cb)
      end,
    },
    {
      name = "unpause_container",
      call = function(E, cb)
        E.unpause_container("abc123", cb)
      end,
    },
    {
      name = "restart_container",
      call = function(E, cb)
        E.restart_container("abc123", cb)
      end,
    },
    {
      name = "stop_container",
      call = function(E, cb)
        E.stop_container("abc123", cb)
      end,
    },
    {
      name = "remove_container",
      call = function(E, cb)
        E.remove_container("abc123", cb)
      end,
    },
    {
      name = "remove_network",
      call = function(E, cb)
        E.remove_network("bridge", cb)
      end,
    },
    {
      name = "remove_volume",
      call = function(E, cb)
        E.remove_volume("data", cb)
      end,
    },
  }

  for _, case in ipairs(CASES) do
    it(case.name .. " reports success on exit 0", function()
      exit_code = 0
      local E = require("sandbox.adapters.docker.engine")
      local ok, err
      run_and_settle(function()
        case.call(E, function(o, e)
          ok, err = o, e
        end)
      end, function()
        return ok ~= nil
      end)

      assert.is_true(ok)
      assert.is_nil(err)
    end)

    it(case.name .. " reports the exit code on failure", function()
      exit_code = 137
      local E = require("sandbox.adapters.docker.engine")
      local ok, err
      run_and_settle(function()
        case.call(E, function(o, e)
          ok, err = o, e
        end)
      end, function()
        return ok ~= nil
      end)

      assert.is_false(ok)
      assert.are.equal("exit code 137", err)
    end)

    it(case.name .. " tolerates no callback at all", function()
      exit_code = 137
      local E = require("sandbox.adapters.docker.engine")
      assert.has_no.errors(function()
        case.call(E, nil)
        vim.wait(50)
      end)
    end)
  end
end)

describe("adapters.docker.images.remove_image", function()
  local real_jobstart
  local exit_code, stderr_lines

  before_each(function()
    real_jobstart = vim.fn.jobstart
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.fn.jobstart = function(_argv, opts)
      if opts.on_stderr and stderr_lines then
        opts.on_stderr(1, stderr_lines)
      end
      opts.on_exit(1, exit_code)
      return 1
    end
    fake_run_argv.reload_prefix("sandbox.adapters.docker.")
  end)

  after_each(function()
    vim.fn.jobstart = real_jobstart
  end)

  it("surfaces stderr when the removal is refused", function()
    exit_code = 1
    stderr_lines = { "Error response from daemon: conflict: unable to delete", "container abc123 is using it" }
    local E = require("sandbox.adapters.docker.engine")
    local ok, err
    run_and_settle(function()
      E.remove_image("nginx", function(o, e)
        ok, err = o, e
      end)
    end, function()
      return ok ~= nil
    end)

    assert.is_false(ok)
    assert.are.equal(table.concat(stderr_lines, "\n"), err)
  end)

  it("falls back to the exit code when nothing was written to stderr", function()
    exit_code = 5
    stderr_lines = nil
    local E = require("sandbox.adapters.docker.engine")
    local ok, err
    run_and_settle(function()
      E.remove_image("nginx", function(o, e)
        ok, err = o, e
      end)
    end, function()
      return ok ~= nil
    end)

    assert.is_false(ok)
    assert.are.equal("exit code 5", err)
  end)
end)

describe("adapters.docker.containers.run_container", function()
  local real_jobstart
  local exit_code, stdout_lines, stderr_lines

  before_each(function()
    real_jobstart = vim.fn.jobstart
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.fn.jobstart = function(_argv, opts)
      if stdout_lines then
        opts.on_stdout(1, stdout_lines)
      end
      if stderr_lines then
        opts.on_stderr(1, stderr_lines)
      end
      opts.on_exit(1, exit_code)
      return 1
    end
    fake_run_argv.reload_prefix("sandbox.adapters.docker.")
    stdout_lines, stderr_lines = nil, nil
  end)

  after_each(function()
    vim.fn.jobstart = real_jobstart
  end)

  it("hands back the new container id, stripped of the newline it arrives with", function()
    exit_code = 0
    stdout_lines = { "9f2c1d0e4b7a", "" }
    local E = require("sandbox.adapters.docker.engine")
    local ok, result
    run_and_settle(function()
      E.run_container({ image = "alpine" }, function(o, r)
        ok, result = o, r
      end)
    end, function()
      return ok ~= nil
    end)

    assert.is_true(ok)
    assert.are.equal("9f2c1d0e4b7a", result)
  end)

  it("reports nil rather than an empty string when the daemon printed no id", function()
    exit_code = 0
    stdout_lines = { "" }
    local E = require("sandbox.adapters.docker.engine")
    local ok, result, called
    run_and_settle(function()
      E.run_container({ image = "alpine" }, function(o, r)
        ok, result, called = o, r, true
      end)
    end, function()
      return called == true
    end)

    assert.is_true(ok)
    assert.is_nil(result)
  end)

  it("surfaces stderr on a failed run", function()
    exit_code = 125
    stderr_lines = { "Unable to find image 'nope:latest' locally" }
    local E = require("sandbox.adapters.docker.engine")
    local ok, result
    run_and_settle(function()
      E.run_container({ image = "nope" }, function(o, r)
        ok, result = o, r
      end)
    end, function()
      return ok ~= nil
    end)

    assert.is_false(ok)
    assert.are.equal("Unable to find image 'nope:latest' locally", result)
  end)

  -- PRIN-20/ERR-03: `jobstart` returning <= 0 means `on_exit` never fires at
  -- all (0: invalid arguments, -1: cmd[1] not executable) -- without
  -- checking the return, this function returned as if a container had
  -- started, and the caller reported neither success nor failure.
  it("reports a failed spawn through on_done instead of returning as if one had started", function()
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.fn.jobstart = function()
      return -1
    end
    local E = require("sandbox.adapters.docker.engine")
    local ok, result
    run_and_settle(function()
      E.run_container({ image = "alpine" }, function(o, r)
        ok, result = o, r
      end)
    end, function()
      return ok ~= nil
    end)

    assert.is_false(ok)
    assert.is_not_nil(result)
  end)
end)

describe("adapters.docker: blocking commands propagate the captured output as err", function()
  after_each(function()
    fake_run_argv.reset()
  end)

  local CASES = {
    {
      name = "start_container",
      call = function(E)
        return E.start_container("abc123")
      end,
    },
    {
      name = "rename_container",
      call = function(E)
        return E.rename_container("abc123", "web")
      end,
    },
    {
      name = "cp_container",
      call = function(E)
        return E.cp_container("a", "abc123:/b")
      end,
    },
    {
      name = "tag_image",
      call = function(E)
        return E.tag_image("a", "b")
      end,
    },
    {
      name = "save_image",
      call = function(E)
        return E.save_image("a", "/tmp/a.tar")
      end,
    },
    {
      name = "load_image",
      call = function(E)
        return E.load_image("/tmp/a.tar")
      end,
    },
    {
      name = "create_volume",
      call = function(E)
        return E.create_volume("data")
      end,
    },
    {
      name = "create_network",
      call = function(E)
        return E.create_network("net")
      end,
    },
    {
      name = "connect_network",
      call = function(E)
        return E.connect_network("net", "abc123")
      end,
    },
    {
      name = "disconnect_network",
      call = function(E)
        return E.disconnect_network("net", "abc123")
      end,
    },
    {
      name = "login_registry",
      call = function(E)
        return E.login_registry("alice", "pw", "reg")
      end,
    },
    {
      name = "logout_registry",
      call = function(E)
        return E.logout_registry("reg")
      end,
    },
  }

  for _, case in ipairs(CASES) do
    it(case.name .. " returns false plus the raw CLI text", function()
      fake_run_argv.install({ ok = false, output = "Error response from daemon: no such thing" })
      fake_run_argv.reload_prefix("sandbox.adapters.docker.")
      local E = require("sandbox.adapters.docker.engine")

      local ok, err = case.call(E)

      assert.is_false(ok)
      assert.are.equal("Error response from daemon: no such thing", err)
    end)

    it(case.name .. " returns true and no err on success", function()
      fake_run_argv.install({ ok = true, output = "whatever" })
      fake_run_argv.reload_prefix("sandbox.adapters.docker.")
      local E = require("sandbox.adapters.docker.engine")

      local ok, err = case.call(E)

      assert.is_true(ok)
      assert.is_nil(err)
    end)
  end
end)

describe("adapters.docker: async commands fall back to the exit code", function()
  after_each(function()
    fake_run_argv.reset()
  end)

  local CASES = {
    {
      name = "prune_containers",
      call = function(E, cb)
        return E.prune_containers(cb)
      end,
    },
    {
      name = "prune_images",
      call = function(E, cb)
        return E.prune_images(cb)
      end,
    },
    {
      name = "prune_networks",
      call = function(E, cb)
        return E.prune_networks(cb)
      end,
    },
    {
      name = "prune_volumes",
      call = function(E, cb)
        return E.prune_volumes(cb)
      end,
    },
  }

  for _, case in ipairs(CASES) do
    it(case.name .. " prefers the captured output over the exit code", function()
      fake_run_argv.install({ ok = false, output = "  permission denied\n", code = 1 })
      fake_run_argv.reload_prefix("sandbox.adapters.docker.")
      local E = require("sandbox.adapters.docker.engine")

      local ok, err
      case.call(E, function(o, e)
        ok, err = o, e
      end)

      assert.is_false(ok)
      assert.are.equal("permission denied", err)
    end)

    it(case.name .. " names the exit code when the command said nothing", function()
      fake_run_argv.install({ ok = false, output = "   \n ", code = 42 })
      fake_run_argv.reload_prefix("sandbox.adapters.docker.")
      local E = require("sandbox.adapters.docker.engine")

      local ok, err
      case.call(E, function(o, e)
        ok, err = o, e
      end)

      assert.is_false(ok)
      assert.are.equal("exit code 42", err)
    end)
  end

  it("pull_image reports the captured output as the error", function()
    fake_run_argv.install({ ok = false, output = "manifest unknown", code = 1 })
    fake_run_argv.reload_prefix("sandbox.adapters.docker.")
    local E = require("sandbox.adapters.docker.engine")

    local ok, err
    E.pull_image("nope:latest", function(o, e)
      ok, err = o, e
    end)

    assert.is_false(ok)
    assert.are.equal("manifest unknown", err)
  end)

  it("push_image reports the captured output as the error", function()
    fake_run_argv.install({ ok = false, output = "denied: requested access to the resource is denied", code = 1 })
    fake_run_argv.reload_prefix("sandbox.adapters.docker.")
    local E = require("sandbox.adapters.docker.engine")

    local ok, err
    E.push_image("nope:latest", function(o, e)
      ok, err = o, e
    end)

    assert.is_false(ok)
    assert.are.equal("denied: requested access to the resource is denied", err)
  end)
end)
