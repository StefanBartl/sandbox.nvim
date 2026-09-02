--- Covers sandbox.hover: the image reference under the cursor, the gate that
--- keeps an engine start off the automatic trigger, and the two-call/one-call
--- split in the lookup.
---
--- Measured against a live docker engine on the machine this was written on,
--- and the numbers are why the module is shaped this way:
---
---     alpine:edge            pulled, no container      754 ms   2 engine calls
---     lazyvim_starter:latest pulled, 1 container       560 ms   2 engine calls
---     nginx:1.27-alpine      not pulled                286 ms   1 engine call
---     init.lua:42            declined                    1 ms   0 engine calls
---
--- Every one of them answered `false` on the automatic trigger.

describe("sandbox.hover", function()
  local hover

  --- A hover.nvim registry stand-in that honours `on_request`, so the specs
  --- do not need hover.nvim installed and do not depend on its version.
  local function fake_registry()
    local R = { positions = {}, registered = {} }
    function R.register(name, contribution)
      R.registered[name] = contribution
      R.positions[name] = nil
      for _, entry in ipairs(contribution.positions or {}) do
        if type(entry) == "table" and type(entry.fn) == "function" then
          R.positions[name] = { fn = entry.fn, on_request = entry.on_request == true }
        elseif type(entry) == "function" then
          R.positions[name] = { fn = entry, on_request = false }
        end
      end
    end
    function R.position_at(bufnr, row, col, opts)
      local force = type(opts) == "table" and opts.force == true
      for _, entry in pairs(R.positions) do
        if force or not entry.on_request then
          local ok, content = pcall(entry.fn, bufnr, row, col)
          if ok and type(content) == "table" then
            return content
          end
        end
      end
      return nil
    end
    return R
  end

  local function with_registry(R, fn)
    local saved = package.loaded["hover.registry"]
    package.loaded["hover.registry"] = R
    local ok, err = pcall(fn)
    package.loaded["hover.registry"] = saved
    if not ok then
      error(err, 0)
    end
  end

  --- A buffer holding one line, and the registered contribution asked at a
  --- column in it -- the whole path a real `:Hover show` takes.
  local function ask(R, line, col, opts)
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { line })
    local content = R.position_at(bufnr, 1, col, opts)
    vim.api.nvim_buf_delete(bufnr, { force = true })
    return content
  end

  before_each(function()
    package.loaded["sandbox.hover"] = nil
    hover = require("sandbox.hover")
  end)

  after_each(function()
    hover._reset()
  end)

  -- The reference test, run before any process is started. Getting this wrong
  -- in the permissive direction costs an engine start on a file reference.
  describe("the reference under the cursor", function()
    it("reads a plain name:tag", function()
      local name, tag = hover.image_at("FROM nginx:1.27-alpine", 8)
      assert.equals("nginx", name)
      assert.equals("1.27-alpine", tag)
    end)

    it("reads it from anywhere inside the reference", function()
      local line = "  image: alpine:edge"
      for col = 9, #line - 1 do
        local name, tag = hover.image_at(line, col)
        assert.equals("alpine", name, "column " .. col)
        assert.equals("edge", tag)
      end
    end)

    -- The collision this module lives next to: `nginx:1.27` and `init.lua:42`
    -- are the same shape, and a file reference must be declined here before
    -- an engine is started, because starting one is the expensive part.
    it("declines a file reference wearing the same shape", function()
      assert.is_nil(hover.image_at("-- siehe init.lua:42", 12))
      assert.is_nil(hover.image_at("src/config.yml:10", 4))
      assert.is_nil(hover.image_at("README.md:1", 2))
    end)

    -- A registry host's dots sit in an earlier component, and the extension
    -- test looks only at the last one. Without that split, every image from
    -- ghcr.io or docker.io would be declined as a file.
    it("keeps a registry host's dots out of the extension test", function()
      local name, tag = hover.image_at("FROM ghcr.io/open-webui/open-webui:main", 20)
      assert.equals("ghcr.io/open-webui/open-webui", name)
      assert.equals("main", tag)
    end)

    it("declines a digest", function()
      assert.is_nil(hover.image_at("FROM alpine@sha256:abc123", 8))
    end)

    it("declines a bare name with no tag, and a bare tag", function()
      assert.is_nil(hover.image_at("FROM alpine", 8))
      assert.is_nil(hover.image_at("FROM :edge", 7))
    end)

    it("declines whitespace and the empty line", function()
      assert.is_nil(hover.image_at("FROM alpine:edge", 4))
      assert.is_nil(hover.image_at("", 0))
      assert.is_nil(hover.image_at(nil, 0))
    end)
  end)

  describe("registration", function()
    it("registers a position preview that is asked only on request", function()
      local R = fake_registry()
      with_registry(R, function()
        assert.is_true(hover.setup())
        local entry = R.positions["sandbox.nvim"]
        assert.is_not_nil(entry)
        assert.is_true(entry.on_request, "an engine start must not ride the automatic trigger")
      end)
    end)

    it("registers once, however often it is called", function()
      local R = fake_registry()
      with_registry(R, function()
        assert.is_true(hover.setup())
        assert.is_true(hover.setup())
        assert.equals(1, vim.tbl_count(R.positions))
      end)
    end)

    it("declines when hover.nvim is absent", function()
      local saved = package.loaded["hover.registry"]
      local saved_preload = package.preload["hover.registry"]
      package.loaded["hover.registry"] = nil
      package.preload["hover.registry"] = function()
        error("not installed")
      end
      local registered = hover.setup()
      package.preload["hover.registry"] = saved_preload
      package.loaded["hover.registry"] = saved
      assert.is_false(registered)
    end)

    -- A registry that simply ignored an unknown key would look identical to
    -- one that honours it, so the probe asks by behaviour. Registering into
    -- such a registry would put a 300-to-750 ms engine start on every
    -- CursorHold, and that is a stutter nobody would trace back to here.
    it("declines a registry that ignores on_request", function()
      local R = fake_registry()
      function R.position_at(bufnr, row, col)
        for _, entry in pairs(R.positions) do
          pcall(entry.fn, bufnr, row, col)
        end
        return nil
      end
      with_registry(R, function()
        assert.is_false(hover.setup())
        assert.is_nil(R.positions["sandbox.nvim"], "and leaves nothing registered")
      end)
    end)

    it("leaves no probe behind when it succeeds", function()
      local R = fake_registry()
      with_registry(R, function()
        assert.is_true(hover.setup())
        assert.is_nil(R.positions["sandbox.nvim.probe"])
      end)
    end)
  end)

  describe("the answer", function()
    local saved_get_engine
    local calls

    --- Stand in for the engine, and count what was asked of it.
    local function stub_engine(images, containers)
      calls = { images = 0, containers = 0 }
      local sandbox = require("sandbox")
      saved_get_engine = sandbox.get_engine
      sandbox.get_engine = function()
        return {
          list_images = function()
            calls.images = calls.images + 1
            return images
          end,
          list_containers = function()
            calls.containers = calls.containers + 1
            return containers
          end,
        }
      end
    end

    after_each(function()
      if saved_get_engine then
        require("sandbox").get_engine = saved_get_engine
        saved_get_engine = nil
      end
    end)

    it("reports a pulled image with its size and id", function()
      stub_engine({ { repository = "alpine", tag = "edge", size = "12.1MB", id = "115729ec5cb0" } }, {})
      local R = fake_registry()
      with_registry(R, function()
        hover.setup()
        local content = ask(R, "FROM alpine:edge", 8, { force = true })
        local text = table.concat(content.lines, "\n")
        assert.equals("alpine:edge", content.title)
        assert.is_truthy(text:find("12.1MB", 1, true))
        assert.is_truthy(text:find("115729ec5cb0", 1, true))
        assert.is_truthy(text:find("no container", 1, true))
      end)
    end)

    it("names the containers running from it", function()
      stub_engine(
        { { repository = "lazyvim_starter", tag = "latest", size = "505MB" } },
        { { image = "lazyvim_starter:latest", name = "mystifying_shtern", status = "exited" } }
      )
      local R = fake_registry()
      with_registry(R, function()
        hover.setup()
        local text = table.concat(ask(R, "FROM lazyvim_starter:latest", 8, { force = true }).lines, "\n")
        assert.is_truthy(text:find("1 container", 1, true))
        assert.is_truthy(text:find("mystifying_shtern", 1, true))
      end)
    end)

    -- "not pulled" is the complete answer on its own. Measured, the second
    -- engine call is the difference between 286 ms and 560 ms, and it would
    -- add nothing to the float.
    it("reports a missing image without asking for containers", function()
      stub_engine({ { repository = "alpine", tag = "edge" } }, {})
      local R = fake_registry()
      with_registry(R, function()
        hover.setup()
        local text = table.concat(ask(R, "FROM nginx:1.27-alpine", 8, { force = true }).lines, "\n")
        assert.is_truthy(text:find("not pulled", 1, true))
        assert.equals(1, calls.images)
        assert.equals(0, calls.containers, "a miss must cost one engine call, not two")
      end)
    end)

    -- Proven live against a stopped daemon: an engine that cannot answer must
    -- produce silence, not a confident "not pulled". Those are different
    -- facts, and only one of them is known.
    it("stays silent when the engine cannot answer", function()
      local sandbox = require("sandbox")
      saved_get_engine = sandbox.get_engine
      sandbox.get_engine = function()
        return {
          list_images = function()
            return nil
          end,
        }
      end
      local R = fake_registry()
      with_registry(R, function()
        hover.setup()
        assert.is_nil(ask(R, "FROM alpine:edge", 8, { force = true }))
      end)
    end)

    it("is not asked at all on the automatic trigger", function()
      stub_engine({ { repository = "alpine", tag = "edge", size = "12.1MB" } }, {})
      local R = fake_registry()
      with_registry(R, function()
        hover.setup()
        assert.is_nil(ask(R, "FROM alpine:edge", 8))
        assert.equals(0, calls.images, "the engine must never be started by a CursorHold")
      end)
    end)
  end)
end)
