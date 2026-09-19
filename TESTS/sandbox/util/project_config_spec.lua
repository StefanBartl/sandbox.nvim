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
end)
