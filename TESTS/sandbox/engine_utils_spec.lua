--- Covers `engine_utils`'s central distinction: an engine being *installed*
--- and an engine being able to *answer* are different questions, and this
--- module used to ask only the first.
---
--- The bug it is written against, found 2026-09-02: on a machine with Podman
--- Desktop installed but its Linux VM stopped, `podman` is on `PATH`, wins the
--- preference order, and every call fails after ~370 ms -- while a running
--- Docker engine sits beside it and is never asked. Nothing said so; the
--- container hover simply answered nothing.
---
--- Neither `PATH` nor a container daemon is touched here: `is_executable` and
--- the probe are both faked, which is the only way this can run in a CI that
--- has neither.

describe("sandbox.engine_utils", function()
  local engine_utils

  --- Reload the module and fake both of its questions about the world.
  ---
  --- `installed` is the set on `PATH`; `live` is the subset whose daemon
  --- answers. Returns a table whose `probes` counts how often the expensive
  --- question was asked -- the memoization is a behaviour, not an
  --- implementation detail, because the probe costs a process start.
  ---@param installed table<string, boolean>
  ---@param live table<string, boolean>
  local function fake(installed, live)
    package.loaded["sandbox.engine_utils"] = nil
    engine_utils = require("sandbox.engine_utils")
    local state = { probes = 0 }

    ---@diagnostic disable-next-line: duplicate-set-field
    engine_utils.is_executable = function(cmd)
      return installed[cmd] == true
    end
    -- Stands in for the `vim.system({name, "version"})` call. Faked at the
    -- module's own seam rather than by faking `vim.system`, so the test says
    -- what it means: "this engine answers", not "this argv exits 0". The
    -- probe itself is covered separately, below.
    ---@diagnostic disable-next-line: duplicate-set-field
    engine_utils.responds = function(name)
      if not engine_utils.is_executable(name) then
        return false
      end
      state.probes = state.probes + 1
      return live[name] == true
    end

    return state
  end

  after_each(function()
    package.loaded["sandbox.engine_utils"] = nil
  end)

  describe("get_engine -- the cheap pick, PATH only", function()
    it("prefers podman over docker over nerdctl", function()
      fake({ podman = true, docker = true, nerdctl = true }, {})
      assert.are.equal("podman", engine_utils.get_engine())
    end)

    it("takes the next one when the preferred is not installed", function()
      fake({ docker = true, nerdctl = true }, {})
      assert.are.equal("docker", engine_utils.get_engine())
    end)

    it("asks nothing about liveness -- this one runs at startup", function()
      local state = fake({ podman = true, docker = true }, { docker = true })
      engine_utils.get_engine()
      assert.are.equal(0, state.probes)
    end)
  end)

  describe("get_live_engine -- the pick that has to be right", function()
    it("skips an installed engine whose daemon does not answer", function()
      -- The reported machine, exactly: podman installed, VM stopped, docker
      -- running. The old detection returned podman here and everything after
      -- it failed silently.
      fake({ podman = true, docker = true }, { docker = true })
      assert.are.equal("docker", engine_utils.get_live_engine())
    end)

    it("still prefers podman when podman answers", function()
      fake({ podman = true, docker = true }, { podman = true, docker = true })
      assert.are.equal("podman", engine_utils.get_live_engine())
    end)

    it("falls back to the installed one when none answers", function()
      -- Not nil and not an error: "podman is not running" is actionable,
      -- "no engine" on a machine with two installed is not.
      fake({ podman = true, docker = true }, {})
      assert.are.equal("podman", engine_utils.get_live_engine())
    end)

    it("never probes an engine that is not installed", function()
      local state = fake({ docker = true }, { docker = true })
      engine_utils.get_live_engine()
      assert.are.equal(1, state.probes)
    end)
  end)

  describe("installed", function()
    it("lists what is on PATH, in preference order", function()
      fake({ nerdctl = true, docker = true }, {})
      assert.are.same({ "docker", "nerdctl" }, engine_utils.installed())
    end)

    it("is empty when nothing is installed", function()
      fake({}, {})
      assert.are.same({}, engine_utils.installed())
    end)
  end)

  describe("responds -- memoization", function()
    -- Not a micro-optimization: the probe is a process start, measured at
    -- ~385 ms whether the daemon answers or refuses. Asking per call would
    -- put that on every hover, every completion and every list refresh.
    it("asks once per engine and remembers the answer", function()
      package.loaded["sandbox.engine_utils"] = nil
      local utils = require("sandbox.engine_utils")
      local calls = 0
      ---@diagnostic disable-next-line: duplicate-set-field
      utils.is_executable = function()
        return true
      end
      -- Fake the process, not the memo: the memo is what is under test.
      local system = vim.system
      -- The fake answers only `wait`, which is all `responds` asks of it.
      -- Claiming to be a whole `vim.SystemObj` would be a lie, so the
      -- mismatch is silenced where it is reported -- on the return, not on
      -- the assignment.
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.system = function()
        calls = calls + 1
        ---@diagnostic disable-next-line: return-type-mismatch
        return {
          wait = function()
            return { code = 0 }
          end,
        }
      end

      assert.is_true(utils.responds("docker"))
      assert.is_true(utils.responds("docker"))
      assert.is_true(utils.responds("docker"))
      assert.are.equal(1, calls)

      utils.forget()
      assert.is_true(utils.responds("docker"))
      assert.are.equal(2, calls)

      vim.system = system
    end)

    it("counts a non-zero exit as silence", function()
      package.loaded["sandbox.engine_utils"] = nil
      local utils = require("sandbox.engine_utils")
      ---@diagnostic disable-next-line: duplicate-set-field
      utils.is_executable = function()
        return true
      end
      local system = vim.system
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.system = function()
        ---@diagnostic disable-next-line: return-type-mismatch
        return {
          wait = function()
            -- What a stopped podman actually returns.
            return { code = 125 }
          end,
        }
      end

      assert.is_false(utils.responds("podman"))

      vim.system = system
    end)
  end)
end)

-- The remaining branches, added in the 2026-09 coverage round: the
-- empty-machine fallback, the probe's own failure modes, and the part of the
-- memoization that is a trade-off rather than a win -- a `false` is remembered
-- just as long as a `true`.
describe("sandbox.engine_utils, the edges", function()
  local real_system

  before_each(function()
    real_system = vim.system
    package.loaded["sandbox.engine_utils"] = nil
    package.loaded["sandbox.notify"] = nil
  end)

  after_each(function()
    vim.system = real_system
    package.loaded["sandbox.engine_utils"] = nil
    package.loaded["sandbox.notify"] = nil
  end)

  --- @return table utils, table notices
  local function with_notify()
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
    local utils = require("sandbox.engine_utils")
    return utils, notices
  end

  it("names a machine with no engine at all, and still answers with one", function()
    local utils, notices = with_notify()
    ---@diagnostic disable-next-line: duplicate-set-field
    utils.is_executable = function()
      return false
    end

    -- Returning nil here would make every caller's `engines[name]` lookup
    -- report "Invalid engine: nil" instead of the real problem.
    assert.are.equal("docker", utils.get_engine())
    assert.are.equal("error", notices[1].level)
    assert.is_truthy(notices[1].msg:find("No supported container engine", 1, true))
  end)

  it("get_live_engine on an empty machine reports once and falls back", function()
    local utils, notices = with_notify()
    ---@diagnostic disable-next-line: duplicate-set-field
    utils.is_executable = function()
      return false
    end

    assert.are.equal("docker", utils.get_live_engine())
    assert.are.equal(1, #notices)
  end)

  it("gives the probe a timeout, because a hung daemon must not take Neovim with it", function()
    local utils = with_notify()
    ---@diagnostic disable-next-line: duplicate-set-field
    utils.is_executable = function()
      return true
    end
    local waited_with
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.system = function()
      ---@diagnostic disable-next-line: return-type-mismatch
      return {
        wait = function(_, timeout)
          waited_with = timeout
          return { code = 0 }
        end,
      }
    end

    utils.responds("docker")

    assert.are.equal(3000, waited_with)
  end)

  it("counts a probe that raises as silence rather than letting it escape", function()
    local utils = with_notify()
    ---@diagnostic disable-next-line: duplicate-set-field
    utils.is_executable = function()
      return true
    end
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.system = function()
      error("spawn failed: EACCES")
    end

    assert.is_false(utils.responds("docker"))
  end)

  it("counts a probe that answers with nothing as silence", function()
    local utils = with_notify()
    ---@diagnostic disable-next-line: duplicate-set-field
    utils.is_executable = function()
      return true
    end
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.system = function()
      ---@diagnostic disable-next-line: return-type-mismatch
      return {
        wait = function()
          return nil
        end,
      }
    end

    assert.is_false(utils.responds("docker"))
  end)

  it("does not probe an uninstalled engine, and remembers that too", function()
    local utils = with_notify()
    local probes = 0
    ---@diagnostic disable-next-line: duplicate-set-field
    utils.is_executable = function()
      return false
    end
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.system = function()
      probes = probes + 1
      ---@diagnostic disable-next-line: return-type-mismatch
      return {
        wait = function()
          return { code = 0 }
        end,
      }
    end

    assert.is_false(utils.responds("docker"))
    assert.is_false(utils.responds("docker"))
    assert.are.equal(0, probes)
  end)

  it("remembers a NO for the session -- starting the daemon afterwards needs `engine reset`", function()
    -- The deliberate half of the memoization, pinned because it is the half a
    -- user notices: the probe costs a process start, so a negative answer is
    -- cached exactly like a positive one, and `:Sandbox engine reset` (which
    -- calls `forget`) is the documented way out.
    local utils = with_notify()
    ---@diagnostic disable-next-line: duplicate-set-field
    utils.is_executable = function()
      return true
    end
    local daemon_up = false
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.system = function()
      ---@diagnostic disable-next-line: return-type-mismatch
      return {
        wait = function()
          return { code = daemon_up and 0 or 125 }
        end,
      }
    end

    assert.is_false(utils.responds("podman"))

    daemon_up = true
    assert.is_false(utils.responds("podman"), "the cached NO is the point")

    utils.forget()
    assert.is_true(utils.responds("podman"))
  end)

  it("asks lib.nvim's memoized executable check, not vim.fn.executable directly", function()
    local utils = with_notify()
    local asked = {}
    package.loaded["lib.nvim.core"] = {
      has_exec = function(cmd)
        asked[#asked + 1] = cmd
        return cmd == "docker"
      end,
    }

    assert.is_true(utils.is_executable("docker"))
    assert.is_false(utils.is_executable("podman"))
    assert.are.same({ "docker", "podman" }, asked)

    package.loaded["lib.nvim.core"] = nil
  end)
end)
