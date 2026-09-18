-- The telescope.nvim front-end (lua/sandbox/telescope/*.lua and
-- lua/telescope/_extensions/sandbox.lua) is an optional, opt-in surface:
-- telescope.nvim is neither a runtime dependency of sandbox.nvim's own
-- setup() path nor a CI checkout (see TESTS/README.md). That is a reason to
-- never require the real telescope.nvim here, not a reason to leave the
-- wiring untested -- picker.lua's own comment says these mirror
-- sandbox.ui.list_actions' `{ lhs, desc, fn }` keymap shape, and getting the
-- ref/describe logic or the key-to-command wiring wrong would only ever
-- surface interactively, one picker at a time.
--
-- `telescope.pickers`/`finders`/`config`/`actions`/`actions.state` are
-- doubled via `package.loaded`, exactly the way `ui.kit` prompts are doubled
-- elsewhere in this suite (see TESTS/README.md's seam table): what is
-- asserted is the configuration sandbox.telescope.picker.build() hands to
-- telescope, and the callbacks it wires up, never a real rendered picker.
--
-- `sandbox.telescope.containers`/`images`/`wsl` each `require()` their
-- dependencies (including `sandbox.telescope.picker`) *inside* the function
-- they return, not at module load time -- so, unlike the adapters, no
-- `reload()` dance is needed: swapping `package.loaded` before each call is
-- enough for the next call to pick the fake up.
---@diagnostic disable: need-check-nil

describe("sandbox.telescope.picker", function()
  local captured_picker_opts
  local select_default_fn
  local map_calls
  local close_calls
  local selected_entry

  before_each(function()
    captured_picker_opts = nil
    select_default_fn = nil
    map_calls = {}
    close_calls = {}
    selected_entry = nil

    package.loaded["telescope.pickers"] = {
      new = function(_, opts)
        captured_picker_opts = opts
        return {
          find = function() end,
        }
      end,
    }
    package.loaded["telescope.finders"] = {
      new_table = function(opts)
        return opts
      end,
    }
    package.loaded["telescope.config"] = {
      values = {
        generic_sorter = function()
          return {}
        end,
      },
    }
    package.loaded["telescope.actions"] = {
      select_default = {
        replace = function(_, fn)
          select_default_fn = fn
        end,
      },
      close = function(bufnr)
        close_calls[#close_calls + 1] = bufnr
      end,
    }
    package.loaded["telescope.actions.state"] = {
      get_selected_entry = function()
        return selected_entry
      end,
    }
    package.loaded["sandbox.telescope.picker"] = nil
  end)

  after_each(function()
    package.loaded["telescope.pickers"] = nil
    package.loaded["telescope.finders"] = nil
    package.loaded["telescope.config"] = nil
    package.loaded["telescope.actions"] = nil
    package.loaded["telescope.actions.state"] = nil
    package.loaded["sandbox.telescope.picker"] = nil
  end)

  --- @return table calls one entry per invocation, in order
  local function build(extra_keys)
    local calls = {}
    local keys = {
      {
        lhs = "<CR>",
        desc = "default",
        fn = function(item)
          calls[#calls + 1] = { action = "default", item = item }
        end,
      },
    }
    for _, k in ipairs(extra_keys or {}) do
      keys[#keys + 1] = k
    end

    require("sandbox.telescope.picker").build({
      title = "Sandbox Things",
      items = { { id = "a" }, { id = "b" } },
      entry = function(item)
        return { display = "[" .. item.id .. "]", ordinal = item.id }
      end,
      keys = keys,
    })
    return calls
  end

  it("hands the title and items straight through to the finder", function()
    build()

    assert.are.equal("Sandbox Things", captured_picker_opts.prompt_title)
    assert.are.same({ { id = "a" }, { id = "b" } }, captured_picker_opts.finder.results)
  end)

  it("wraps each item through opts.entry via entry_maker", function()
    build()

    local made = captured_picker_opts.finder.entry_maker({ id = "a" })
    assert.are.same({ id = "a" }, made.value)
    assert.are.equal("[a]", made.display)
    assert.are.equal("a", made.ordinal)
  end)

  it("replaces the default <CR> action with keys[1], closing the prompt first", function()
    local calls = build()
    selected_entry = { value = { id = "a" } }

    captured_picker_opts.attach_mappings(42, function() end)
    select_default_fn()

    assert.are.same({ 42 }, close_calls)
    assert.are.same({ { action = "default", item = { id = "a" } } }, calls)
  end)

  it("does nothing beyond closing when <CR> fires with no selection", function()
    local calls = build()
    selected_entry = nil

    captured_picker_opts.attach_mappings(7, function() end)
    select_default_fn()

    assert.are.same({ 7 }, close_calls)
    assert.are.same({}, calls)
  end)

  it("binds every key from index 2 on through map(), closing before calling fn", function()
    local extra_calls = {}
    local calls = build({
      {
        lhs = "<C-x>",
        desc = "extra",
        fn = function(item)
          extra_calls[#extra_calls + 1] = item
        end,
      },
    })
    selected_entry = { value = { id = "b" } }

    captured_picker_opts.attach_mappings(9, function(modes, lhs, fn)
      map_calls[#map_calls + 1] = { modes = modes, lhs = lhs, fn = fn }
    end)

    assert.are.equal(1, #map_calls)
    assert.are.same({ "i", "n" }, map_calls[1].modes)
    assert.are.equal("<C-x>", map_calls[1].lhs)

    map_calls[1].fn()

    assert.are.same({ 9 }, close_calls)
    assert.are.same({ { id = "b" } }, extra_calls)
    -- keys[1]'s own fn (the default) must not fire for a different key.
    assert.are.same({}, calls)
  end)

  it("skips calling a mapped key's fn when there is no selection", function()
    local extra_calls = {}
    build({
      {
        lhs = "<C-x>",
        desc = "extra",
        fn = function(item)
          extra_calls[#extra_calls + 1] = item
        end,
      },
    })
    selected_entry = nil

    captured_picker_opts.attach_mappings(3, function(modes, lhs, fn)
      map_calls[#map_calls + 1] = { modes = modes, lhs = lhs, fn = fn }
    end)
    map_calls[1].fn()

    assert.are.same({ 3 }, close_calls)
    assert.are.same({}, extra_calls)
  end)

  it("attach_mappings returns true, so telescope keeps its own default mappings too", function()
    build()

    assert.is_true(captured_picker_opts.attach_mappings(1, function() end))
  end)
end)

describe("sandbox.telescope.containers", function()
  local captured

  --- @param opts { engine?: string|false, containers?: table[], err?: string }
  local function load(opts)
    captured = nil

    package.loaded["sandbox.notify"] = {
      error = function() end,
      warn = function() end,
    }
    package.loaded["sandbox"] = {
      get_engine = function()
        if opts.engine == false then
          return nil
        end
        return opts.engine or "docker"
      end,
    }
    package.loaded["sandbox.core.usecases.containers.list_containers"] = function(_engine, cb)
      if opts.containers then
        cb(opts.containers, nil)
      else
        cb(nil, opts.err or "boom")
      end
    end
    package.loaded["sandbox.bindings.usrcmds.container_commands"] = {
      inspect = function() end,
      start = function() end,
      stop = function() end,
      restart = function() end,
      logs = function() end,
      remove = function() end,
    }
    package.loaded["sandbox.telescope.picker"] = {
      build = function(built_opts)
        captured = built_opts
      end,
    }

    package.loaded["sandbox.telescope.containers"] = nil
    return require("sandbox.telescope.containers")
  end

  after_each(function()
    package.loaded["sandbox.notify"] = nil
    package.loaded["sandbox"] = nil
    package.loaded["sandbox.core.usecases.containers.list_containers"] = nil
    package.loaded["sandbox.bindings.usrcmds.container_commands"] = nil
    package.loaded["sandbox.telescope.picker"] = nil
    package.loaded["sandbox.telescope.containers"] = nil
  end)

  it("does nothing when there is no engine", function()
    local run = load({ engine = false })

    run()

    assert.is_nil(captured)
  end)

  it("builds no picker and notifies when the usecase fails", function()
    local errors = {}
    local run = load({ err = "daemon down" })
    package.loaded["sandbox.notify"].error = function(msg)
      errors[#errors + 1] = msg
    end

    run()

    assert.is_nil(captured)
    assert.are.equal(1, #errors)
    assert.is_truthy(errors[1]:find("daemon down", 1, true))
  end)

  it("formats known and unknown fields the same way the list view does", function()
    local run = load({
      containers = {
        { id = "0123456789abcdef", name = "web", status = "running" },
        {},
      },
    })

    run()

    assert.are.equal("Sandbox Containers", captured.title)
    assert.are.equal("[running] web (0123456789ab)", captured.entry(captured.items[1]).display)
    assert.are.equal("[unknown] <no name> (<no id>)", captured.entry(captured.items[2]).display)
  end)

  it("wires every key to the matching container_commands call, ref'd by id first", function()
    local run = load({ containers = { { id = "abc123", name = "web" } } })
    run()

    local seen = {}
    local cc = package.loaded["sandbox.bindings.usrcmds.container_commands"]
    for name, verb in pairs({
      ["<CR>"] = "inspect",
      ["<C-s>"] = "start",
      ["<C-x>"] = "stop",
      ["<C-r>"] = "restart",
      ["<C-l>"] = "logs",
      ["<C-d>"] = "remove",
    }) do
      cc[verb] = function(ref)
        seen[name] = ref
      end
    end

    for _, key in ipairs(captured.keys) do
      key.fn({ id = "abc123", name = "web" })
    end

    for lhs, verb in pairs({
      ["<CR>"] = "inspect",
      ["<C-s>"] = "start",
      ["<C-x>"] = "stop",
      ["<C-r>"] = "restart",
      ["<C-l>"] = "logs",
      ["<C-d>"] = "remove",
    }) do
      assert.are.equal("abc123", seen[lhs], verb)
    end
  end)

  it("falls back to the name as ref when a container has no id", function()
    local run = load({ containers = { { name = "web" } } })
    run()

    local inspected
    package.loaded["sandbox.bindings.usrcmds.container_commands"].inspect = function(ref)
      inspected = ref
    end

    captured.keys[1].fn({ name = "web" })

    assert.are.equal("web", inspected)
  end)
end)

describe("sandbox.telescope.images", function()
  local captured

  --- @param opts { images?: table[], is_podman?: boolean, err?: string, no_engine?: boolean }
  local function load(opts)
    captured = nil

    package.loaded["sandbox.notify"] = {
      error = function() end,
      warn = function() end,
    }
    package.loaded["sandbox"] = {
      get_engine = function()
        if opts.no_engine then
          return nil
        end
        return "docker"
      end,
      resolve_engine_name = function()
        return opts.is_podman and "podman" or "docker"
      end,
    }
    package.loaded["sandbox.core.usecases.images.list_images"] = function(_engine)
      if opts.images then
        return opts.images, nil
      end
      return nil, opts.err or "boom"
    end
    package.loaded["sandbox.bindings.usrcmds.image_commands"] = {
      inspect = function() end,
      history = function() end,
      remove = function() end,
    }
    package.loaded["sandbox.telescope.picker"] = {
      build = function(built_opts)
        captured = built_opts
      end,
    }

    package.loaded["sandbox.telescope.images"] = nil
    return require("sandbox.telescope.images")
  end

  after_each(function()
    package.loaded["sandbox.notify"] = nil
    package.loaded["sandbox"] = nil
    package.loaded["sandbox.core.usecases.images.list_images"] = nil
    package.loaded["sandbox.bindings.usrcmds.image_commands"] = nil
    package.loaded["sandbox.telescope.picker"] = nil
    package.loaded["sandbox.telescope.images"] = nil
  end)

  it("does nothing when there is no engine", function()
    local run = load({ no_engine = true })

    run()

    assert.is_nil(captured)
  end)

  it("notifies and builds no picker when the usecase fails", function()
    local errors = {}
    local run = load({ err = "no daemon" })
    package.loaded["sandbox.notify"].error = function(msg)
      errors[#errors + 1] = msg
    end

    run()

    assert.is_nil(captured)
    assert.is_truthy(errors[1]:find("no daemon", 1, true))
  end)

  it("describes docker/nerdctl's normalized shape, ref'd as repo:tag", function()
    local run = load({
      images = { { id = "0123456789abcdef", repository = "nginx", tag = "1.27", size = "142MB" } },
    })
    run()

    local e = captured.entry(captured.items[1])
    assert.are.equal("[nginx:1.27] 0123456789ab (142MB)", e.display)

    local inspected
    package.loaded["sandbox.bindings.usrcmds.image_commands"].inspect = function(ref)
      inspected = ref
    end
    captured.keys[1].fn(captured.items[1])
    assert.are.equal("nginx:1.27", inspected)
  end)

  it("refs a docker <none> repository by id instead of 'nil:nil'", function()
    local run = load({
      images = { { id = "0123456789abcdef", repository = "<none>", tag = "<none>" } },
    })
    run()

    local inspected
    package.loaded["sandbox.bindings.usrcmds.image_commands"].inspect = function(ref)
      inspected = ref
    end
    captured.keys[1].fn(captured.items[1])
    assert.are.equal("0123456789abcdef", inspected)
  end)

  it("describes podman's raw shape, splitting Names at the last colon", function()
    local run = load({
      is_podman = true,
      images = { { Id = "0123456789abcdef", Names = { "registry.example.com:5000/team/app:1.0" } } },
    })
    run()

    local e = captured.entry(captured.items[1])
    assert.are.equal("[registry.example.com:5000/team/app:1.0] 0123456789ab", e.display)

    local historied
    package.loaded["sandbox.bindings.usrcmds.image_commands"].history = function(ref)
      historied = ref
    end
    captured.keys[2].fn(captured.items[1])
    assert.are.equal("registry.example.com:5000/team/app:1.0", historied)
  end)

  it("refs a podman image with no name by its Id", function()
    local run = load({
      is_podman = true,
      images = { { Id = "0123456789abcdef" } },
    })
    run()

    local removed
    package.loaded["sandbox.bindings.usrcmds.image_commands"].remove = function(ref)
      removed = ref
    end
    captured.keys[3].fn(captured.items[1])
    assert.are.equal("0123456789abcdef", removed)
  end)
end)

describe("sandbox.telescope.wsl", function()
  local captured

  --- @param opts { available?: boolean, distros?: table[], err?: string }
  local function load(opts)
    captured = nil

    package.loaded["sandbox.notify"] = {
      error = function() end,
      warn = function() end,
    }
    package.loaded["sandbox.bindings.usrcmds.wsl_commands"] = {
      available = function()
        return opts.available ~= false
      end,
      exec = function() end,
      start = function() end,
      stop = function() end,
      set_default = function() end,
    }
    package.loaded["sandbox.adapters.wsl.engine"] = {}
    package.loaded["sandbox.core.usecases.wsl.list_distros"] = function(_engine)
      if opts.distros then
        return opts.distros, nil
      end
      return nil, opts.err or "boom"
    end
    package.loaded["sandbox.telescope.picker"] = {
      build = function(built_opts)
        captured = built_opts
      end,
    }

    package.loaded["sandbox.telescope.wsl"] = nil
    return require("sandbox.telescope.wsl")
  end

  after_each(function()
    package.loaded["sandbox.notify"] = nil
    package.loaded["sandbox.bindings.usrcmds.wsl_commands"] = nil
    package.loaded["sandbox.adapters.wsl.engine"] = nil
    package.loaded["sandbox.core.usecases.wsl.list_distros"] = nil
    package.loaded["sandbox.telescope.picker"] = nil
    package.loaded["sandbox.telescope.wsl"] = nil
  end)

  it("warns and builds no picker when wsl.exe is not on PATH", function()
    local warnings = {}
    local run = load({ available = false })
    package.loaded["sandbox.notify"].warn = function(msg)
      warnings[#warnings + 1] = msg
    end

    run()

    assert.is_nil(captured)
    assert.are.equal(1, #warnings)
  end)

  it("notifies and builds no picker when the usecase fails", function()
    local errors = {}
    local run = load({ err = "wsl not responding" })
    package.loaded["sandbox.notify"].error = function(msg)
      errors[#errors + 1] = msg
    end

    run()

    assert.is_nil(captured)
    assert.is_truthy(errors[1]:find("wsl not responding", 1, true))
  end)

  it("marks the default distro in the display text", function()
    local run = load({
      distros = {
        { name = "Ubuntu", state = "Running", default = true },
        { name = "Alpine", state = "Stopped", default = false },
      },
    })
    run()

    assert.are.equal("Ubuntu [Running] (default)", captured.entry(captured.items[1]).display)
    assert.are.equal("Alpine [Stopped]", captured.entry(captured.items[2]).display)
  end)

  it("wires every key to the matching wsl_commands call, by distro name", function()
    local run = load({ distros = { { name = "Ubuntu", state = "Running", default = true } } })
    run()

    local seen = {}
    local wc = package.loaded["sandbox.bindings.usrcmds.wsl_commands"]
    wc.exec = function(name)
      seen["<CR>"] = name
    end
    wc.start = function(name)
      seen["<C-s>"] = name
    end
    wc.stop = function(name)
      seen["<C-x>"] = name
    end
    wc.set_default = function(name)
      seen["<C-d>"] = name
    end

    for _, key in ipairs(captured.keys) do
      key.fn(captured.items[1])
    end

    assert.are.equal("Ubuntu", seen["<CR>"])
    assert.are.equal("Ubuntu", seen["<C-s>"])
    assert.are.equal("Ubuntu", seen["<C-x>"])
    assert.are.equal("Ubuntu", seen["<C-d>"])
  end)
end)

describe("telescope._extensions.sandbox", function()
  after_each(function()
    package.loaded["telescope"] = nil
    package.loaded["sandbox.telescope.containers"] = nil
    package.loaded["sandbox.telescope.images"] = nil
    package.loaded["sandbox.telescope.wsl"] = nil
    package.loaded["telescope._extensions.sandbox"] = nil
  end)

  it("registers the three pickers under their own names, unmodified", function()
    local registered
    package.loaded["telescope"] = {
      register_extension = function(spec)
        registered = spec
        return spec
      end,
    }
    local containers_fn = function() end
    local images_fn = function() end
    local wsl_fn = function() end
    package.loaded["sandbox.telescope.containers"] = containers_fn
    package.loaded["sandbox.telescope.images"] = images_fn
    package.loaded["sandbox.telescope.wsl"] = wsl_fn

    require("telescope._extensions.sandbox")

    assert.are.equal(containers_fn, registered.exports.containers)
    assert.are.equal(images_fn, registered.exports.images)
    assert.are.equal(wsl_fn, registered.exports.wsl)
  end)
end)
