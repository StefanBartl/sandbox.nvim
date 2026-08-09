local fake_run_argv = require("tests.sandbox.helpers.fake_run_argv")

describe("adapters.*.registry", function()
  after_each(function()
    fake_run_argv.reset()
  end)

  it("docker login pipes the password via stdin, never argv", function()
    local state = fake_run_argv.install({ ok = true, output = "Login Succeeded" })
    fake_run_argv.reload({ "sandbox.adapters.docker.registry.login" })
    local M = require("sandbox.adapters.docker.registry.login")

    local ok = M.login("myuser", "s3cr3t", "registry.example.com")

    assert.is_true(ok)
    local call = state.calls[1]
    assert.are.same({ "docker", "login", "--username", "myuser", "--password-stdin", "registry.example.com" }, call.cmd)
    assert.are.equal("s3cr3t", call.input)
    for _, arg in ipairs(call.cmd) do
      assert.is_nil(arg:find("s3cr3t", 1, true))
    end
  end)

  it("docker login omits the registry argument when none is given (defaults to Docker Hub)", function()
    local state = fake_run_argv.install({ ok = true })
    fake_run_argv.reload({ "sandbox.adapters.docker.registry.login" })
    local M = require("sandbox.adapters.docker.registry.login")

    M.login("myuser", "s3cr3t")

    assert.are.same({ "docker", "login", "--username", "myuser", "--password-stdin" }, state.calls[1].cmd)
  end)

  it("docker logout builds `docker logout [registry]`", function()
    local state = fake_run_argv.install({ ok = true })
    fake_run_argv.reload({ "sandbox.adapters.docker.registry.logout" })
    local M = require("sandbox.adapters.docker.registry.logout")

    M.logout("registry.example.com")

    assert.are.same({ "docker", "logout", "registry.example.com" }, state.calls[1].cmd)
  end)

  it("podman login pipes the password via stdin, never argv", function()
    local state = fake_run_argv.install({ ok = true })
    fake_run_argv.reload({ "sandbox.adapters.podman.registry.login" })
    local M = require("sandbox.adapters.podman.registry.login")

    M.login("myuser", "s3cr3t", "quay.io")

    local call = state.calls[1]
    assert.are.same({ "podman", "login", "--username", "myuser", "--password-stdin", "quay.io" }, call.cmd)
    assert.are.equal("s3cr3t", call.input)
  end)
end)
