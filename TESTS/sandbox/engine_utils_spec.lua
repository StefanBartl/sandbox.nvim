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
