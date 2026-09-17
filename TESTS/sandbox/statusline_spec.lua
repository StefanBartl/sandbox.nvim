-- The statusline component is the only ambient caller in the plugin: it runs
-- on every redraw, which is many times a second, and it must never block, never
-- notify, and never stack up one `ps` per redraw.
--
-- Those three are the properties under test here, plus the stale-while-
-- revalidate contract: `status()` returns the cached text *immediately* and
-- the refreshed value shows up on a later redraw. No engine is ever reached --
-- `sandbox.get_engine` is a double whose `list_containers` records how often
-- it was asked and with what options.
---@diagnostic disable: need-check-nil

describe("sandbox.statusline", function()
  local calls

  --- @param opts { engine_name: string|nil, containers: table[]|nil, throws: boolean?, defer: boolean?, ttl: integer? }
  --- @return table statusline
  local function fresh(opts)
    calls = { list = 0, opts = nil, pending = nil }

    package.loaded["sandbox.statusline"] = nil
    package.loaded["sandbox.config"] = nil
    require("sandbox.config").options.status_cache_ttl_ms = opts.ttl

    package.loaded["sandbox"] = {
      resolve_engine_name = function()
        return opts.engine_name
      end,
      get_engine = function()
        if opts.engine_name == nil then
          return nil
        end
        return {
          list_containers = function(on_done, call_opts)
            calls.list = calls.list + 1
            calls.opts = call_opts
            if opts.throws then
              error("list_containers not implemented.")
            end
            if opts.defer then
              calls.pending = on_done
              return
            end
            on_done(opts.containers)
          end,
        }
      end,
    }

    return require("sandbox.statusline")
  end

  after_each(function()
    package.loaded["sandbox.statusline"] = nil
    package.loaded["sandbox"] = nil
    package.loaded["sandbox.config"] = nil
  end)

  local RUNNING_TWO_OF_FIVE = {
    { name = "a", status = "running" },
    { name = "b", status = "Up 3 minutes" },
    { name = "c", status = "exited" },
    { name = "d", status = "paused" },
    { name = "e", status = "created" },
  }

  it("counts only what is running, against the total", function()
    local statusline = fresh({ engine_name = "docker", containers = RUNNING_TWO_OF_FIVE, ttl = 0 })

    -- First redraw kicks off the refresh; the fake answers synchronously, so
    -- the value is already in the cache for the second.
    statusline.status()

    assert.are.equal("docker (2/5)", statusline.status())
  end)

  it("says 0/0 for an engine with nothing on it", function()
    local statusline = fresh({ engine_name = "podman", containers = {}, ttl = 0 })

    statusline.status()

    assert.are.equal("podman (0/0)", statusline.status())
  end)

  it("suppresses the progress indicator -- an ambient refresh is not news", function()
    local statusline = fresh({ engine_name = "docker", containers = {}, ttl = 0 })

    statusline.status()

    assert.are.same({ progress = false }, calls.opts)
  end)

  it("asks once per TTL, not once per redraw", function()
    local statusline = fresh({ engine_name = "docker", containers = {}, ttl = 60000 })

    for _ = 1, 20 do
      statusline.status()
    end

    assert.are.equal(1, calls.list)
  end)

  it("never stacks up a second ps while the first is still in flight", function()
    local statusline = fresh({ engine_name = "docker", containers = {}, ttl = 0, defer = true })

    for _ = 1, 10 do
      statusline.status()
    end

    assert.are.equal(1, calls.list)

    -- Once the in-flight call answers, the next redraw may ask again.
    calls.pending({})
    statusline.status()
    assert.are.equal(2, calls.list)
  end)

  it("returns the stale text on the redraw that triggers the refresh", function()
    local statusline = fresh({ engine_name = "docker", containers = RUNNING_TWO_OF_FIVE, ttl = 0, defer = true })

    -- Nothing cached yet: the first call can only return "".
    assert.are.equal("", statusline.status())

    calls.pending(RUNNING_TWO_OF_FIVE)
    assert.are.equal("docker (2/5)", statusline.status())
  end)

  it("degrades to the engine name when the engine cannot answer", function()
    local statusline = fresh({ engine_name = "docker", containers = nil, ttl = 0 })

    statusline.status()

    assert.are.equal("docker", statusline.status())
  end)

  it("degrades to the engine name when list_containers is not implemented", function()
    -- The ports' stubs raise, and a raise inside a statusline redraw is the
    -- worst place for one -- hence the pcall around the call itself.
    local statusline = fresh({ engine_name = "docker", throws = true, ttl = 0 })

    assert.has_no.errors(function()
      statusline.status()
    end)
    assert.are.equal("docker", statusline.status())
  end)

  it("is empty, not an error, when no engine resolves", function()
    local statusline = fresh({ engine_name = nil, ttl = 0 })

    assert.has_no.errors(function()
      statusline.status()
    end)
    assert.are.equal("", statusline.status())
    assert.are.equal(0, calls.list)
  end)

  it("falls back to a 3s TTL for a nonsensical status_cache_ttl_ms", function()
    local statusline = fresh({ engine_name = "docker", containers = {}, ttl = "soon" })

    for _ = 1, 5 do
      statusline.status()
    end

    -- A bad value must not be read as "0 ms", which would mean one `ps` per
    -- redraw.
    assert.are.equal(1, calls.list)
  end)

  it("exposes the same function under lualine_component", function()
    local statusline = fresh({ engine_name = "docker", containers = {}, ttl = 0 })

    assert.are.equal(statusline.status, statusline.lualine_component)
  end)
end)
