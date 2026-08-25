--- Covers sandbox.resolve_engine_name()'s three-way precedence:
--- vim.g.sandbox_engine (session override) > .sandboxrc (per-project) >
--- config.options.engine (configured/detected default).

describe("sandbox.resolve_engine_name", function()
  local tmpdir

  before_each(function()
    vim.g.sandbox_engine = nil
    tmpdir = vim.fn.tempname()
    vim.fn.mkdir(tmpdir, "p")
  end)

  after_each(function()
    vim.g.sandbox_engine = nil
    vim.fn.delete(tmpdir, "rf")
  end)

  local function reload()
    package.loaded["sandbox"] = nil
    package.loaded["sandbox.config"] = nil
    package.loaded["sandbox.util.project_config"] = nil
    return require("sandbox")
  end

  it("falls back to config.options.engine when nothing else is set", function()
    local orig = vim.fn.getcwd()
    vim.cmd("cd " .. vim.fn.fnameescape(tmpdir))
    local sandbox = reload()
    sandbox.setup({ engine = "docker" })

    assert.are.equal("docker", sandbox.resolve_engine_name())

    vim.cmd("cd " .. vim.fn.fnameescape(orig))
  end)

  it(".sandboxrc overrides the configured default", function()
    vim.fn.writefile({ "engine=podman" }, tmpdir .. "/.sandboxrc")
    local orig = vim.fn.getcwd()
    vim.cmd("cd " .. vim.fn.fnameescape(tmpdir))
    local sandbox = reload()
    sandbox.setup({ engine = "docker" })

    assert.are.equal("podman", sandbox.resolve_engine_name())

    vim.cmd("cd " .. vim.fn.fnameescape(orig))
  end)

  it("vim.g.sandbox_engine overrides both .sandboxrc and the configured default", function()
    vim.fn.writefile({ "engine=podman" }, tmpdir .. "/.sandboxrc")
    local orig = vim.fn.getcwd()
    vim.cmd("cd " .. vim.fn.fnameescape(tmpdir))
    local sandbox = reload()
    sandbox.setup({ engine = "docker" })
    vim.g.sandbox_engine = "nerdctl"

    assert.are.equal("nerdctl", sandbox.resolve_engine_name())

    vim.cmd("cd " .. vim.fn.fnameescape(orig))
  end)

  it("get_engine() returns the implementation matching the resolved name", function()
    local sandbox = reload()
    sandbox.setup({ engine = "docker" })
    vim.g.sandbox_engine = "podman"

    local engine = sandbox.get_engine()

    assert.are.equal(require("sandbox.adapters.podman.engine"), engine)
  end)
end)
