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

  it("returns nil when no .sandboxrc exists", function()
    with_cwd(tmpdir, function()
      package.loaded["sandbox.util.project_config"] = nil
      local M = require("sandbox.util.project_config")
      assert.is_nil(M.read_engine_override())
    end)
  end)

  it("reads a valid engine= line for each supported engine", function()
    for _, engine in ipairs({ "docker", "podman", "nerdctl" }) do
      vim.fn.writefile({ "engine=" .. engine }, tmpdir .. "/.sandboxrc")
      with_cwd(tmpdir, function()
        package.loaded["sandbox.util.project_config"] = nil
        local M = require("sandbox.util.project_config")
        assert.are.equal(engine, M.read_engine_override())
      end)
    end
  end)

  it("ignores an invalid engine value", function()
    vim.fn.writefile({ "engine=bogus" }, tmpdir .. "/.sandboxrc")
    with_cwd(tmpdir, function()
      package.loaded["sandbox.util.project_config"] = nil
      local M = require("sandbox.util.project_config")
      assert.is_nil(M.read_engine_override())
    end)
  end)

  it("tolerates surrounding whitespace and unrelated keys", function()
    vim.fn.writefile({ "# comment-ish noise line", "other = 1", "  engine = podman  " }, tmpdir .. "/.sandboxrc")
    with_cwd(tmpdir, function()
      package.loaded["sandbox.util.project_config"] = nil
      local M = require("sandbox.util.project_config")
      assert.are.equal("podman", M.read_engine_override())
    end)
  end)
end)
