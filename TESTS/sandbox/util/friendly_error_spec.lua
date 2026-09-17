-- Every failure the user ever sees goes through this function: each command
-- module calls `friendly_error(err)` for the popup text while handing the raw
-- text to `sandbox.logger`. So this is the one place where a wall of docker
-- stderr becomes one line -- and the one place where the useful half can get
-- cut off.
---@diagnostic disable: need-check-nil

describe("sandbox.util.friendly_error", function()
  --- @param max_error_length any
  --- @return function
  local function fresh(max_error_length)
    package.loaded["sandbox.util.friendly_error"] = nil
    package.loaded["sandbox.config"] = nil
    local config = require("sandbox.config")
    config.options.max_error_length = max_error_length
    return require("sandbox.util.friendly_error")
  end

  after_each(function()
    package.loaded["sandbox.util.friendly_error"] = nil
    package.loaded["sandbox.config"] = nil
  end)

  describe("the daemon-unreachable family", function()
    local DOCKER = "Docker daemon not reachable - is Docker Desktop running?"
    local PODMAN = "Podman not reachable - is the podman machine/service running?"

    local CASES = {
      { raw = "Cannot connect to the Docker daemon at unix:///var/run/docker.sock.", want = DOCKER },
      { raw = "error during connect: Get http://%2F%2F.%2Fpipe%2Fdocker_engine/v1.24/version", want = DOCKER },
      { raw = "The system cannot find the file specified. dockerDesktopLinuxEngine", want = DOCKER },
      { raw = "docker daemon is not running", want = DOCKER },
      { raw = "Cannot connect to Podman. Please verify your connection", want = PODMAN },
      { raw = "unable to connect to Podman socket", want = PODMAN },
    }

    for _, case in ipairs(CASES) do
      it("maps " .. case.raw:sub(1, 34) .. "...", function()
        local friendly_error = fresh(200)
        assert.are.equal(case.want, friendly_error(case.raw))
      end)
    end

    it("matches regardless of case, since the engines disagree about it", function()
      local friendly_error = fresh(200)
      assert.are.equal(DOCKER, friendly_error("CANNOT CONNECT TO THE DOCKER DAEMON"))
    end)

    it("matches a pattern buried in a multi-line dump", function()
      local friendly_error = fresh(200)
      local raw = "docker: something went wrong\nCannot connect to the Docker daemon\nSee 'docker run --help'."
      assert.are.equal(DOCKER, friendly_error(raw))
    end)

    it("treats the patterns as plain text, not as Lua patterns", function()
      -- The table is matched with `find(..., 1, true)`. A raw error containing
      -- regex-ish punctuation must not blow up or accidentally match.
      local friendly_error = fresh(200)
      assert.are.equal("error: %-%s [a-z]+", friendly_error("error: %-%s [a-z]+"))
    end)
  end)

  describe("everything else falls back to the first line", function()
    it("takes the first line and trims it", function()
      local friendly_error = fresh(200)
      assert.are.equal("no such container: abc", friendly_error("  no such container: abc  \nStack trace:\n  ..."))
    end)

    it("handles CRLF as a line break, not as part of the line", function()
      local friendly_error = fresh(200)
      assert.are.equal("first line", friendly_error("first line\r\nsecond line"))
    end)

    it("says 'unknown error' for nil, empty and whitespace-only input", function()
      local friendly_error = fresh(200)
      assert.are.equal("unknown error", friendly_error(nil))
      assert.are.equal("unknown error", friendly_error(""))
      assert.are.equal("unknown error", friendly_error("   \n\n"))
    end)

    it("caps a long line and says where the rest is", function()
      local friendly_error = fresh(20)
      local raw = string.rep("x", 100)

      local out = friendly_error(raw)

      assert.are.equal(string.rep("x", 20), out:sub(1, 20))
      assert.is_truthy(out:find("full text:", 1, true))
      -- lib.nvim is present in this suite, so the hint may name its viewer.
      assert.is_truthy(out:find(":LibLogger show", 1, true) or out:find("raise max_error_length", 1, true))
    end)

    it("points at raising the cap when lib.nvim's logger is not installed", function()
      local friendly_error = fresh(10)
      package.loaded["lib.nvim.logger"] = nil
      package.preload["lib.nvim.logger"] = function()
        error("module 'lib.nvim.logger' not found")
      end

      local out = friendly_error(string.rep("y", 50))

      package.preload["lib.nvim.logger"] = nil
      assert.is_truthy(out:find("raise max_error_length", 1, true))
    end)

    it("does not touch a line that fits", function()
      local friendly_error = fresh(200)
      assert.are.equal("short", friendly_error("short"))
    end)

    it("reads the cap from the live config, not from a value captured at load", function()
      local friendly_error = fresh(200)
      local raw = string.rep("z", 60)

      assert.are.equal(raw, friendly_error(raw))

      require("sandbox.config").options.max_error_length = 10
      assert.are_not.equal(raw, friendly_error(raw))
    end)

    local BAD_CAPS = { 0, -1, "200", {}, false }
    for i, bad in ipairs(BAD_CAPS) do
      it("falls back to 200 for a nonsensical max_error_length (#" .. i .. ")", function()
        local friendly_error = fresh(bad)
        local out = friendly_error(string.rep("q", 500))

        assert.are.equal(string.rep("q", 200), out:sub(1, 200))
      end)
    end
  end)
end)
