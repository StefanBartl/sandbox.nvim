local fake_run_argv = require("tests.sandbox.helpers.fake_run_argv")

describe("adapters.docker.containers", function()
  after_each(function()
    fake_run_argv.reset()
  end)

  it("start_container builds `docker start <id>` and reports success", function()
    local state = fake_run_argv.install({ ok = true, output = "abc123" })
    fake_run_argv.reload({ "sandbox.adapters.docker.containers.start_container" })
    local M = require("sandbox.adapters.docker.containers.start_container")

    local ok, err = M.start_container("abc123")

    assert.is_true(ok)
    assert.is_nil(err)
    assert.are.same({ "docker", "start", "abc123" }, state.calls[1].cmd)
  end)

  it("start_container surfaces the captured output as err on failure", function()
    fake_run_argv.install({ ok = false, output = "no such container" })
    fake_run_argv.reload({ "sandbox.adapters.docker.containers.start_container" })
    local M = require("sandbox.adapters.docker.containers.start_container")

    local ok, err = M.start_container("missing")

    assert.is_false(ok)
    assert.are.equal("no such container", err)
  end)

  it("stop_container builds `docker stop --time=1 <id>` via jobstart and calls on_done", function()
    fake_run_argv.reload({ "sandbox.adapters.docker.containers.stop_container" })
    local M = require("sandbox.adapters.docker.containers.stop_container")

    local captured_cmd
    local orig_jobstart = vim.fn.jobstart
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.fn.jobstart = function(cmd, cbs)
      captured_cmd = cmd
      cbs.on_exit(0, 0, "exit")
      return 1
    end

    local done_ok, done_err
    M.stop_container("abc123", function(ok, err)
      done_ok, done_err = ok, err
    end)
    vim.wait(50)

    vim.fn.jobstart = orig_jobstart
    assert.are.same({ "docker", "stop", "--time=1", "abc123" }, captured_cmd)
    assert.is_true(done_ok)
    assert.is_nil(done_err)
  end)

  it("rename_container builds `docker rename <id> <new_name>`", function()
    local state = fake_run_argv.install({ ok = true })
    fake_run_argv.reload({ "sandbox.adapters.docker.containers.rename_container" })
    local M = require("sandbox.adapters.docker.containers.rename_container")

    M.rename_container("abc123", "web-2")

    assert.are.same({ "docker", "rename", "abc123", "web-2" }, state.calls[1].cmd)
  end)

  it("list_containers parses newline-delimited JSON into id/name/status/image", function()
    local lines = table.concat({
      '{"ID":"abc123","Names":"web","State":"running","Image":"nginx"}',
      '{"ID":"def456","Names":"db","State":"exited","Image":"postgres"}',
    }, "\n")
    fake_run_argv.install({ ok = true, output = lines })
    fake_run_argv.reload({ "sandbox.adapters.docker.containers.list_containers" })
    local M = require("sandbox.adapters.docker.containers.list_containers")

    local containers, err = M.list_containers()

    assert.is_nil(err)
    assert.are.equal(2, #containers)
    -- running sorts before exited
    assert.are.equal("web", containers[1].name)
    assert.are.equal("running", containers[1].status)
    assert.are.equal("db", containers[2].name)
  end)
end)
