--- The compose and prune adapters used to call `vim.fn.jobstart` directly,
--- which meant they were the plugin's longest-running commands with no progress
--- indicator — `compose up` pulls and builds images, `prune` walks the whole
--- store. They now go through `util/run_argv`'s async runner, which reports
--- progress for every caller, so these specs pin down that they really do route
--- through it (the fake only records calls that reach `run_argv`) and that the
--- error contract survived the move.

local fake_run_argv = require("TESTS.sandbox.helpers.fake_run_argv")

describe("adapters: long-running commands via run_argv", function()
  after_each(function()
    fake_run_argv.reset()
  end)

  --- One representative per command family; `engine_parity_spec` already
  --- guarantees podman/nerdctl expose the same surface, and the three adapters
  --- differ only in argv[1].
  local cases = {
    {
      module = "sandbox.adapters.docker.compose.up",
      call = function(M, cb)
        return M.up("docker-compose.yml", cb)
      end,
      argv = { "docker", "compose", "-f", "docker-compose.yml", "up", "-d" },
    },
    {
      module = "sandbox.adapters.docker.compose.down",
      call = function(M, cb)
        return M.down("docker-compose.yml", cb)
      end,
      argv = { "docker", "compose", "-f", "docker-compose.yml", "down" },
    },
    {
      module = "sandbox.adapters.docker.compose.restart",
      call = function(M, cb)
        return M.restart("docker-compose.yml", cb)
      end,
      argv = { "docker", "compose", "-f", "docker-compose.yml", "restart" },
    },
    {
      module = "sandbox.adapters.docker.images.prune_images",
      call = function(M, cb)
        return M.prune_images(cb)
      end,
      argv = { "docker", "image", "prune", "-f" },
    },
    {
      module = "sandbox.adapters.docker.containers.prune_containers",
      call = function(M, cb)
        return M.prune_containers(cb)
      end,
      argv = { "docker", "container", "prune", "-f" },
    },
    {
      module = "sandbox.adapters.docker.networks.prune_networks",
      call = function(M, cb)
        return M.prune_networks(cb)
      end,
      argv = { "docker", "network", "prune", "-f" },
    },
    {
      module = "sandbox.adapters.docker.volumes.prune_volumes",
      call = function(M, cb)
        return M.prune_volumes(cb)
      end,
      argv = { "docker", "volume", "prune", "-f" },
    },
  }

  for _, case in ipairs(cases) do
    it(case.module .. " routes through run_argv and reports success", function()
      local state = fake_run_argv.install({ ok = true, output = "" })
      fake_run_argv.reload({ case.module })
      local M = require(case.module)

      local done_ok, done_err
      local handle = case.call(M, function(ok, err)
        done_ok, done_err = ok, err
      end)

      assert.are.same(case.argv, state.calls[1].cmd)
      assert.is_true(done_ok)
      assert.is_nil(done_err)
      -- The handle is what makes the operation cancellable from an interactive
      -- progress style, so it has to be returned rather than swallowed.
      assert.is_function(handle.stop)
    end)

    it(case.module .. " surfaces captured output as err on failure", function()
      fake_run_argv.install({ ok = false, output = "permission denied" })
      fake_run_argv.reload({ case.module })
      local M = require(case.module)

      local done_ok, done_err
      case.call(M, function(ok, err)
        done_ok, done_err = ok, err
      end)

      assert.is_false(done_ok)
      assert.are.equal("permission denied", done_err)
    end)

    it(case.module .. " falls back to the exit code when nothing was written", function()
      fake_run_argv.install({ ok = false, output = "", code = 125 })
      fake_run_argv.reload({ case.module })
      local M = require(case.module)

      local done_err
      case.call(M, function(_, err)
        done_err = err
      end)

      assert.are.equal("exit code 125", done_err)
    end)

    it(case.module .. " tolerates being called without an on_done callback", function()
      fake_run_argv.install({ ok = false, output = "boom" })
      fake_run_argv.reload({ case.module })
      local M = require(case.module)

      -- `on_done` is optional in every one of these signatures, and the fake
      -- invokes the callback synchronously — so a missing guard would raise here.
      assert.has_no.errors(function()
        case.call(M, nil)
      end)
    end)
  end
end)
