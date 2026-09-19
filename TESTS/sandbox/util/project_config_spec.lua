describe("util.project_config", function()
  local tmpdir

  before_each(function()
    tmpdir = vim.fn.tempname()
    vim.fn.mkdir(tmpdir, "p")
  end)

  after_each(function()
    vim.fn.delete(tmpdir, "rf")
  end)

  local function with_cwd(dir, fn)
    local orig = vim.fn.getcwd()
    vim.cmd("cd " .. vim.fn.fnameescape(dir))
    local ok, err = pcall(fn)
    vim.cmd("cd " .. vim.fn.fnameescape(orig))
    if not ok then
      error(err, 0)
    end
  end

  it("returns nil, false when no .sandboxrc exists", function()
    with_cwd(tmpdir, function()
      package.loaded["sandbox.util.project_config"] = nil
      local M = require("sandbox.util.project_config")
      local name, invalid = M.read_engine_override()
      assert.is_nil(name)
      assert.is_false(invalid)
    end)
  end)

  it("reads a valid engine= line for each supported engine", function()
    for _, engine in ipairs({ "docker", "podman", "nerdctl" }) do
      vim.fn.writefile({ "engine=" .. engine }, tmpdir .. "/.sandboxrc")
      with_cwd(tmpdir, function()
        package.loaded["sandbox.util.project_config"] = nil
        local M = require("sandbox.util.project_config")
        local name, invalid = M.read_engine_override()
        assert.are.equal(engine, name)
        assert.is_false(invalid)
      end)
    end
  end)

  -- ERR-10: an invalid value must be reported as "argument there, but
  -- invalid" (nil, true), distinct from "no argument at all" (nil, false) --
  -- a typo in a file written specifically to pin an engine must not behave
  -- exactly like never having written the file.
  it("reports an invalid engine value as invalid, not as absent", function()
    vim.fn.writefile({ "engine=bogus" }, tmpdir .. "/.sandboxrc")
    with_cwd(tmpdir, function()
      package.loaded["sandbox.util.project_config"] = nil
      local M = require("sandbox.util.project_config")
      local name, invalid = M.read_engine_override()
      assert.is_nil(name)
      assert.is_true(invalid)
    end)
  end)

  it("reports a trailing stray token as invalid instead of silently not matching the line", function()
    vim.fn.writefile({ "engine = podman extra-token" }, tmpdir .. "/.sandboxrc")
    with_cwd(tmpdir, function()
      package.loaded["sandbox.util.project_config"] = nil
      local M = require("sandbox.util.project_config")
      local name, invalid = M.read_engine_override()
      assert.is_nil(name)
      assert.is_true(invalid)
    end)
  end)

  it("tolerates surrounding whitespace and unrelated keys", function()
    vim.fn.writefile({ "# comment-ish noise line", "other = 1", "  engine = podman  " }, tmpdir .. "/.sandboxrc")
    with_cwd(tmpdir, function()
      package.loaded["sandbox.util.project_config"] = nil
      local M = require("sandbox.util.project_config")
      local name, invalid = M.read_engine_override()
      assert.are.equal("podman", name)
      assert.is_false(invalid)
    end)
  end)

  -- This is the function `sandbox.resolve_engine_name()` falls through to on
  -- every call that has no `vim.g.sandbox_engine` session override -- which
  -- includes statusline.status() on every redraw. Without a per-cwd cache
  -- that is a filereadable()/readfile() pair against `.sandboxrc` on every
  -- single redraw, cwd unchanged or not.
  it("answers from cache for a cwd it already read, not from a fresh file read", function()
    vim.fn.writefile({ "engine=podman" }, tmpdir .. "/.sandboxrc")
    with_cwd(tmpdir, function()
      package.loaded["sandbox.util.project_config"] = nil
      local M = require("sandbox.util.project_config")

      local first_name = M.read_engine_override()
      assert.are.equal("podman", first_name)

      -- The file changes but the cwd does not -- within the TTL, a cached
      -- answer must keep returning the value it read on first entry into
      -- this cwd rather than re-reading on every call.
      vim.fn.writefile({ "engine=docker" }, tmpdir .. "/.sandboxrc")
      local second_name = M.read_engine_override()
      assert.are.equal("podman", second_name)
    end)
  end)

  -- `:Sandbox engine get`/`get_engine()` also fall through to this function,
  -- and are meant to see a `.sandboxrc` someone just fixed in the *same* cwd
  -- without forcing a `:cd` away and back first -- so the cache must not be
  -- good for the rest of the session, only for the redraw-burst timescale it
  -- exists to collapse.
  it("re-reads once the cache entry's TTL has elapsed, cwd unchanged", function()
    vim.fn.writefile({ "engine=podman" }, tmpdir .. "/.sandboxrc")
    with_cwd(tmpdir, function()
      package.loaded["sandbox.util.project_config"] = nil
      local M = require("sandbox.util.project_config")

      local first_name = M.read_engine_override()
      assert.are.equal("podman", first_name)

      vim.fn.writefile({ "engine=docker" }, tmpdir .. "/.sandboxrc")
      -- vim.wait (not vim.uv.sleep) so the event loop actually turns --
      -- vim.uv.now() is the loop's cached time and only advances on an
      -- iteration, which a raw blocking sleep never triggers.
      vim.wait(600) -- past CACHE_TTL_MS (500ms)
      local second_name = M.read_engine_override()
      assert.are.equal("docker", second_name)
    end)
  end)

  it("re-reads once the cwd actually changes", function()
    local other = vim.fn.tempname()
    vim.fn.mkdir(other, "p")
    vim.fn.writefile({ "engine=podman" }, tmpdir .. "/.sandboxrc")

    local orig = vim.fn.getcwd()
    vim.cmd("cd " .. vim.fn.fnameescape(tmpdir))
    package.loaded["sandbox.util.project_config"] = nil
    local M = require("sandbox.util.project_config")
    local ok, err = pcall(function()
      assert.are.equal("podman", M.read_engine_override())

      -- Leaving for a cwd with no override and back again must pick the
      -- current file content back up, not keep serving the first cwd's
      -- entry from a cache that never distinguished cwds.
      vim.cmd("cd " .. vim.fn.fnameescape(other))
      assert.is_nil((M.read_engine_override()))

      vim.fn.writefile({ "engine=docker" }, tmpdir .. "/.sandboxrc")
      vim.cmd("cd " .. vim.fn.fnameescape(tmpdir))
      assert.are.equal("docker", M.read_engine_override())
    end)
    vim.cmd("cd " .. vim.fn.fnameescape(orig))
    vim.fn.delete(other, "rf")
    if not ok then
      error(err, 0)
    end
  end)
end)
