-- Working directory (`-w`) on `exec_in_container`, across all three engines.
--
-- `exec_in_container` spawns a terminal rather than going through `run_argv`,
-- so the shared `fake_run_argv` helper does not see it — `vim.fn.termopen` is
-- what has to be captured here.
--
-- The property worth pinning is argv *order*: `-w` has to sit before the
-- container id. After it, the flag would be handed to the command running
-- inside the container instead of to the engine, which fails in a way that
-- looks like the command's own error rather than ours.

describe("adapters.*.containers.exec_in_container workdir", function()
  local real_termopen, real_cmd, real_feedkeys
  local captured

  before_each(function()
    captured = nil
    real_termopen, real_cmd, real_feedkeys = vim.fn.termopen, vim.cmd, vim.api.nvim_feedkeys
    vim.fn.termopen = function(argv)
      captured = argv
      return 0
    end
    -- The adapter opens a split and enters terminal mode; neither is what is
    -- under test, and both are noise in a headless run.
    vim.cmd = function() end
    vim.api.nvim_feedkeys = function() end
  end)

  after_each(function()
    vim.fn.termopen, vim.cmd, vim.api.nvim_feedkeys = real_termopen, real_cmd, real_feedkeys
  end)

  local ENGINES = { "docker", "podman", "nerdctl" }

  for _, engine in ipairs(ENGINES) do
    it(engine .. ": no workdir leaves argv untouched", function()
      local M = require("sandbox.adapters." .. engine .. ".containers.exec_in_container")
      M.exec_in_container("abc123", { "sh" })
      assert.are.same({ engine, "exec", "-it", "abc123", "sh" }, captured)
    end)

    it(engine .. ": workdir inserts `-w` before the container id", function()
      local M = require("sandbox.adapters." .. engine .. ".containers.exec_in_container")
      M.exec_in_container("abc123", { "sh" }, "/app")
      assert.are.same({ engine, "exec", "-it", "-w", "/app", "abc123", "sh" }, captured)
    end)

    it(engine .. ": the command tail still follows the id", function()
      local M = require("sandbox.adapters." .. engine .. ".containers.exec_in_container")
      M.exec_in_container("abc123", { "ls", "-la" }, "/srv")
      assert.are.same({ engine, "exec", "-it", "-w", "/srv", "abc123", "ls", "-la" }, captured)
    end)

    it(engine .. ": an empty workdir is treated as none", function()
      local M = require("sandbox.adapters." .. engine .. ".containers.exec_in_container")
      M.exec_in_container("abc123", { "sh" }, "")
      assert.are.same({ engine, "exec", "-it", "abc123", "sh" }, captured)
    end)
  end
end)
