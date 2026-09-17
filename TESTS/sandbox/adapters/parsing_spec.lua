-- How each adapter turns engine output into the shapes the views and the
-- command layer index into -- and what it does with output it cannot parse.
--
-- The two list formats are not interchangeable. Docker and nerdctl are asked
-- for a Go template (`--format "{{json .}}"`) and get one JSON *object per
-- line*; podman is asked for `--format json` and gets one JSON *array*. The
-- parsers are written accordingly, and `argv_matrix_spec` pins the matching
-- flags, so a change on one side without the other shows up here as a decode
-- failure rather than as an empty list on a user's machine.
--
-- A second asymmetry is pinned rather than fixed: podman's `list_images`
-- hands back podman's own JSON objects untouched, where docker's normalizes
-- them to `{id, repository, tag, size}`. That is why there are two image
-- list views in `lua/sandbox/ui/`. It is documented here so the next reader
-- does not "unify" one of them and silently break the other view.
---@diagnostic disable: need-check-nil
local fake_run_argv = require("TESTS.sandbox.helpers.fake_run_argv")

--- Install a fake whose captured output is `output`, then load `engine`'s
--- aggregator against it.
--- @param engine string
--- @param opts table
--- @return table
local function engine_with(engine, opts)
  fake_run_argv.install(opts)
  fake_run_argv.reload_prefix("sandbox.adapters." .. engine .. ".")
  return require("sandbox.adapters." .. engine .. ".engine")
end

local function ndjson(...)
  return table.concat({ ... }, "\n")
end

describe("adapters: list_containers", function()
  after_each(function()
    fake_run_argv.reset()
  end)

  for _, engine in ipairs({ "docker", "nerdctl" }) do
    it(engine .. " reads one JSON object per line and sorts running first, then by name", function()
      local E = engine_with(engine, {
        ok = true,
        output = ndjson(
          '{"ID":"c3","Names":"zulu","State":"exited","Image":"alpine"}',
          '{"ID":"c1","Names":"web","State":"running","Image":"nginx"}',
          '{"ID":"c2","Names":"api","State":"running","Image":"node"}'
        ),
      })

      local containers, err = E.list_containers()

      assert.is_nil(err)
      assert.are.same({
        { id = "c2", name = "api", status = "running", image = "node" },
        { id = "c1", name = "web", status = "running", image = "nginx" },
        { id = "c3", name = "zulu", status = "exited", image = "alpine" },
      }, containers)
    end)

    it(engine .. " fills in placeholders for fields the engine left out", function()
      local E = engine_with(engine, { ok = true, output = "{}" })

      local containers = E.list_containers()

      assert.are.same({
        { id = "<no id>", name = "<no name>", status = "unknown", image = "<no image>" },
      }, containers)
    end)

    it(engine .. " returns the lines it could parse AND an error naming the ones it could not", function()
      local E = engine_with(engine, {
        ok = true,
        output = ndjson('{"ID":"c1","Names":"web","State":"running","Image":"nginx"}', "not json at all"),
      })

      local containers, err = E.list_containers()

      assert.are.equal(1, #containers)
      assert.are.equal("web", containers[1].name)
      assert.is_not_nil(err)
      assert.is_truthy(err:find("not json at all", 1, true))
    end)

    it(engine .. " returns nil and the raw text when the command failed", function()
      local E = engine_with(engine, { ok = false, output = "Cannot connect to the Docker daemon" })

      local containers, err = E.list_containers()

      assert.is_nil(containers)
      assert.are.equal("Cannot connect to the Docker daemon", err)
    end)
  end

  it("podman reads one JSON array, with Names as a list and Id spelled short", function()
    local E = engine_with("podman", {
      ok = true,
      output = '[{"Id":"c1","Names":["web"],"State":"running","Image":"nginx"},'
        .. '{"Id":"c2","Names":["db"],"State":"exited","Image":"postgres"}]',
    })

    local containers, err = E.list_containers()

    assert.is_nil(err)
    assert.are.same({
      { id = "c1", name = "web", status = "running", image = "nginx" },
      { id = "c2", name = "db", status = "exited", image = "postgres" },
    }, containers)
  end)

  it("podman survives a container with no Names array", function()
    local E = engine_with("podman", {
      ok = true,
      output = '[{"Id":"c1","State":"running","Image":"nginx"}]',
    })

    local containers = E.list_containers()

    assert.are.equal("<no name>", containers[1].name)
  end)

  it("podman reports undecodable output instead of returning an empty list", function()
    local E = engine_with("podman", { ok = true, output = "this is not JSON" })

    local containers, err = E.list_containers()

    assert.is_nil(containers)
    assert.is_not_nil(err)
  end)

  it("delivers the identical values to on_done on the async path", function()
    local E = engine_with("docker", {
      ok = true,
      output = '{"ID":"c1","Names":"web","State":"running","Image":"nginx"}',
    })

    local got, got_err, called
    E.list_containers(function(containers, err)
      got, got_err, called = containers, err, true
    end)

    assert.is_true(called)
    assert.is_nil(got_err)
    assert.are.same({ { id = "c1", name = "web", status = "running", image = "nginx" } }, got)
  end)
end)

describe("adapters: list_images", function()
  after_each(function()
    fake_run_argv.reset()
  end)

  for _, engine in ipairs({ "docker", "nerdctl" }) do
    it(engine .. " normalizes each line to id/repository/tag/size", function()
      local E = engine_with(engine, {
        ok = true,
        output = ndjson(
          '{"ID":"i1","Repository":"nginx","Tag":"latest","Size":"142MB"}',
          '{"ID":"i2","Repository":"alpine","Tag":"3.20","Size":"7.8MB"}'
        ),
      })

      local images, err = E.list_images()

      assert.is_nil(err)
      assert.are.same({
        { id = "i1", repository = "nginx", tag = "latest", size = "142MB" },
        { id = "i2", repository = "alpine", tag = "3.20", size = "7.8MB" },
      }, images)
    end)

    it(engine .. " keeps the parsed images and names the undecodable line", function()
      local E = engine_with(engine, {
        ok = true,
        output = ndjson('{"ID":"i1","Repository":"nginx","Tag":"latest","Size":"142MB"}', "<<garbage>>"),
      })

      local images, err = E.list_images()

      assert.are.equal(1, #images)
      assert.is_truthy(err:find("<<garbage>>", 1, true))
    end)

    it(engine .. " returns nil plus the raw text when the command failed", function()
      local E = engine_with(engine, { ok = false, output = "permission denied" })

      local images, err = E.list_images()

      assert.is_nil(images)
      assert.are.equal("permission denied", err)
    end)
  end

  it("podman hands back its own JSON objects untouched, not the docker shape", function()
    -- Pinned as a contract, not a defect: `ui/image_list_view_podman.lua`
    -- exists precisely because this list has podman's field names on it.
    local E = engine_with("podman", {
      ok = true,
      output = '[{"Id":"i1","Names":["docker.io/library/nginx:latest"],"Size":142000000}]',
    })

    local images, err = E.list_images()

    assert.is_nil(err)
    assert.are.equal(1, #images)
    assert.are.equal("i1", images[1].Id)
    assert.is_nil(images[1].repository)
  end)

  it("podman reports undecodable output with its own message", function()
    local E = engine_with("podman", { ok = true, output = "not json" })

    local images, err = E.list_images()

    assert.is_nil(images)
    assert.are.equal("invalid image JSON output", err)
  end)
end)

describe("adapters: list_networks and list_volumes", function()
  after_each(function()
    fake_run_argv.reset()
  end)

  it("list_networks normalizes id/name/driver/scope", function()
    local E = engine_with("docker", {
      ok = true,
      output = ndjson(
        '{"ID":"n1","Name":"bridge","Driver":"bridge","Scope":"local"}',
        '{"ID":"n2","Name":"host","Driver":"host"}'
      ),
    })

    local networks, err = E.list_networks()

    assert.is_nil(err)
    assert.are.same({
      { id = "n1", name = "bridge", driver = "bridge", scope = "local" },
      { id = "n2", name = "host", driver = "host", scope = "" },
    }, networks)
  end)

  it("list_volumes normalizes name/driver/mountpoint", function()
    local E = engine_with("docker", {
      ok = true,
      output = ndjson(
        '{"Name":"data","Driver":"local","Mountpoint":"/var/lib/docker/volumes/data/_data"}',
        '{"Name":"cache","Driver":"local"}'
      ),
    })

    local volumes, err = E.list_volumes()

    assert.is_nil(err)
    assert.are.same({
      { name = "data", driver = "local", mountpoint = "/var/lib/docker/volumes/data/_data" },
      { name = "cache", driver = "local", mountpoint = "" },
    }, volumes)
  end)

  it("both keep what parsed and report what did not", function()
    local E = engine_with("docker", { ok = true, output = ndjson('{"Name":"data"}', "junk") })

    local volumes, err = E.list_volumes()

    assert.are.equal(1, #volumes)
    assert.is_truthy(err:find("junk", 1, true))
  end)
end)

describe("adapters: inspect_*", function()
  after_each(function()
    fake_run_argv.reset()
  end)

  local CASES = {
    {
      name = "inspect_container",
      noun = "container",
      call = function(E)
        return E.inspect_container("abc123")
      end,
    },
    {
      name = "inspect_image",
      noun = "image",
      call = function(E)
        return E.inspect_image("nginx")
      end,
    },
    {
      name = "inspect_network",
      noun = "network",
      call = function(E)
        return E.inspect_network("bridge")
      end,
    },
    {
      name = "inspect_volume",
      noun = "volume",
      call = function(E)
        return E.inspect_volume("data")
      end,
    },
  }

  for _, case in ipairs(CASES) do
    it(case.name .. " unwraps the engine's single-element array", function()
      local E = engine_with("docker", { ok = true, output = '[{"Id":"abc123","Name":"/web"}]' })

      local result = case.call(E)

      assert.are.equal("abc123", result.Id)
    end)

    it(case.name .. " reports unparsable output as a one-line message, not a crash", function()
      local E = engine_with("docker", { ok = false, output = "Error: No such object: abc123" })

      local result = case.call(E)

      assert.are.equal(1, #result)
      assert.is_truthy(result[1]:find("Invalid JSON output", 1, true))
      assert.is_truthy(result[1]:find("No such object", 1, true))
    end)

    it(case.name .. " reports an empty array as an error rather than returning nil", function()
      local E = engine_with("docker", { ok = true, output = "[]" })

      local result = case.call(E)

      assert.are.equal(1, #result)
      assert.is_truthy(result[1]:find("Error inspecting " .. case.noun, 1, true))
    end)
  end

  it("inspect_container also answers through on_done", function()
    local E = engine_with("docker", { ok = true, output = '[{"Id":"abc123"}]' })

    local got
    E.inspect_container("abc123", function(result)
      got = result
    end)

    assert.are.equal("abc123", got.Id)
  end)
end)

describe("adapters: line-oriented output", function()
  after_each(function()
    fake_run_argv.reset()
  end)

  local CASES = {
    {
      name = "get_logs",
      call = function(E, cb)
        return E.get_logs("abc123", cb)
      end,
    },
    {
      name = "top_container",
      call = function(E, cb)
        return E.top_container("abc123", cb)
      end,
    },
    {
      name = "stats_container",
      call = function(E, cb)
        return E.stats_container("abc123", cb)
      end,
    },
    {
      name = "compose logs",
      call = function(_E, _cb)
        return require("sandbox.adapters.docker.compose_engine").logs("compose.yml")
      end,
    },
    {
      name = "compose ps",
      call = function(_E, _cb)
        return require("sandbox.adapters.docker.compose_engine").ps("compose.yml")
      end,
    },
    {
      name = "history_image",
      call = function(E, _cb)
        return E.history_image("nginx")
      end,
    },
  }

  for _, case in ipairs(CASES) do
    it(case.name .. " splits the captured text into lines, keeping empty ones", function()
      local E = engine_with("docker", { ok = true, output = "first\n\nthird" })

      local lines, err = case.call(E, nil)

      assert.is_nil(err)
      assert.are.same({ "first", "", "third" }, lines)
    end)

    it(case.name .. " returns nil plus the raw text on failure", function()
      local E = engine_with("docker", { ok = false, output = "No such container: abc123" })

      local lines, err = case.call(E, nil)

      assert.is_nil(lines)
      assert.are.equal("No such container: abc123", err)
    end)
  end

  it("get_logs delivers the same split to on_done", function()
    local E = engine_with("docker", { ok = true, output = "a\nb" })

    local got
    E.get_logs("abc123", function(lines)
      got = lines
    end)

    assert.are.same({ "a", "b" }, got)
  end)
end)

describe("adapters.wsl.list_distros", function()
  after_each(function()
    fake_run_argv.reset()
  end)

  --- @param opts table
  --- @return table
  local function wsl_with(opts)
    fake_run_argv.install(opts)
    fake_run_argv.reload_prefix("sandbox.adapters.wsl.")
    return require("sandbox.adapters.wsl.engine")
  end

  it("skips the header line and marks the default distro", function()
    local E = wsl_with({
      ok = true,
      output = table.concat({
        "  NAME              STATE           VERSION",
        "* Ubuntu-24.04      Running         2",
        "  Debian            Stopped         2",
      }, "\n"),
    })

    local distros, err = E.list_distros()

    assert.is_nil(err)
    assert.are.same({
      { name = "Ubuntu-24.04", state = "Running", default = true },
      { name = "Debian", state = "Stopped", default = false },
    }, distros)
  end)

  it("strips the carriage returns wsl.exe writes on Windows", function()
    local E = wsl_with({
      ok = true,
      output = "  NAME   STATE   VERSION\r\n* Ubuntu   Running   2\r\n",
    })

    local distros = E.list_distros()

    assert.are.equal("Ubuntu", distros[1].name)
    assert.are.equal("Running", distros[1].state)
  end)

  it("skips a line it cannot read rather than inventing a distro", function()
    local E = wsl_with({ ok = true, output = "  NAME   STATE   VERSION\n\n  \n* Ubuntu   Running   2" })

    local distros = E.list_distros()

    assert.are.equal(1, #distros)
    assert.are.equal("Ubuntu", distros[1].name)
  end)

  it("returns nil plus the raw text when wsl.exe failed", function()
    local E = wsl_with({ ok = false, output = "There is no distribution with the supplied name." })

    local distros, err = E.list_distros()

    assert.is_nil(distros)
    assert.are.equal("There is no distribution with the supplied name.", err)
  end)

  it("BUG: UTF-16LE output is parsed as if it were text, yielding one junk distro", function()
    -- `list_distros`' own comment says "`wsl --list --verbose` outputs UTF-16
    -- LE on Windows; vim.system decodes it". Nothing decodes it: `text = true`
    -- controls newline handling, not the encoding, and neither
    -- `run_blocking_captured` nor lib.nvim's runner transcodes. What the
    -- parser really receives on Windows is the raw little-endian bytes -- an
    -- ASCII character followed by a NUL. NUL is not `%s`, so `^(%S+)%s+(%S+)`
    -- matches straight across the embedded NULs and the header line is not
    -- recognised as a header either, because splitting on "\n" cannot find a
    -- plain "\n" in "\n\0".
    --
    -- Measured, not inferred: `vim.system({"wsl","--list","--verbose"},
    -- {text = true})` on the author's Windows 11 machine returned 388 bytes
    -- of which 194 were NUL, and running the parser over that real output
    -- produced `name = "\0*\0"`, `state = "\0a\0r\0c\0h\0l\0i\0n\0u\0x\0"`
    -- for the first row and empty names for the rest.
    --
    -- Pinned rather than fixed: decoding UTF-16 changes what every WSL
    -- command returns and deserves its own change. Effect today, on the
    -- platform this feature exists for: `:Sandbox wsl list` shows rows of
    -- mojibake instead of the distros, DISTRO_NAME completion offers them as
    -- candidates, and every `:Sandbox wsl <verb> <name>` built from one of
    -- them is addressed to a distro that does not exist.
    local function utf16le(s)
      return (s:gsub(".", function(c)
        return c .. "\0"
      end))
    end

    local E = wsl_with({
      ok = true,
      output = utf16le("  NAME       STATE     VERSION\n* Ubuntu     Running   2\n  Debian     Stopped   2\n"),
    })

    local distros = E.list_distros()

    for _, d in ipairs(distros) do
      assert.are_not.equal("Ubuntu", d.name)
      assert.are_not.equal("Debian", d.name)
      assert.are_not.equal("Running", d.state)
    end
    -- The header is not recognised as a header either: the first parsed row
    -- carries the default marker into the name field.
    assert.is_truthy(distros[1].name:find("%z"))
  end)
end)
