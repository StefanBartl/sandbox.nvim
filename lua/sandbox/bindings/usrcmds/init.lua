---@module 'sandbox.bindings.usrcmds'
---@brief Registers :Sandbox (and its short alias :Sbx) -- a single
--- lib.nvim.bindings.usercmd.composer verb with three sub-namespaces (container,
--- image, and -- when wsl.exe is reachable -- wsl), e.g. `:Sandbox container
--- list` / `:Sbx image pull <name>`. Replaces the earlier three independent
--- verbs (:Container/:Image/:Wsl): those names were too generic and
--- collided conceptually with unrelated plugins (e.g. an image/png viewer
--- claiming :Image), so every subcommand now hangs off one shared,
--- unambiguous prefix instead.
---@description
--- Breaking change, no compat aliases for the old :Container/:Image/:Wsl
--- verb names. The 7 "*Buffer" terminal-output variants
--- (ContainerStartBuffer, ImagePullBuffer, ...) remain folded into a
--- `--buffer`/`-b` flag on their base subcommand, e.g.
--- `:Sandbox container start <id> --buffer`.
---
--- <container-id>/<image-id>/<distro-name> args complete dynamically against
--- the live engine (docker/podman/wsl). Each list call shells out
--- synchronously (run_argv.run_blocking_captured) with no built-in caching,
--- so a naive per-keystroke <Tab> would shell out repeatedly -- results are
--- cached for `completion_cache_ttl_ms` per list kind, refreshed lazily on the next
--- completion request after expiry.

local composer = require("lib.nvim.bindings.usercmd.composer")

local container_cmds = require("sandbox.bindings.usrcmds.container_commands")
local container_buffer_cmds = require("sandbox.bindings.usrcmds.container_commands_buffer")
local image_cmds = require("sandbox.bindings.usrcmds.image_commands")
local volume_cmds = require("sandbox.bindings.usrcmds.volume_commands")
local network_cmds = require("sandbox.bindings.usrcmds.network_commands")
local compose_cmds = require("sandbox.bindings.usrcmds.compose_commands")
local wsl_cmds = require("sandbox.bindings.usrcmds.wsl_commands")
local engine_cmds = require("sandbox.bindings.usrcmds.engine_commands")
local registry_cmds = require("sandbox.bindings.usrcmds.registry_commands")
local devcontainer_cmds = require("sandbox.bindings.usrcmds.devcontainer_commands")

local M = {}

-- ── Cached dynamic completion ────────────────────────────────────────────

---How long a completion listing stays cached, in ms.
---@return integer
local function cache_ttl_ms()
  local ok, config = pcall(require, "sandbox.config")
  if not ok then
    return 4000
  end
  local n = (config.options or {}).completion_cache_ttl_ms
  return (type(n) == "number" and n >= 0) and n or 4000
end
---@type table<string, { items: string[], at: integer }>
local list_cache = {}

---@internal
---@param key string
---@param fetch fun(): table[]
---@param to_name fun(item: table): string
---@return string[]
local function cached_names(key, fetch, to_name)
  local now = vim.uv.now()
  local entry = list_cache[key]
  if entry and (now - entry.at) < cache_ttl_ms() then
    return entry.items
  end

  -- A misconfigured/unreachable engine makes get_engine()/list_*() call
  -- vim.notify(ERROR) as a side effect -- fine on a real invocation, but
  -- disruptive when it happens to fire while Neovim is computing <Tab>
  -- candidates (getcompletion() surfaces it as a hard error to the caller
  -- even though this function's own pcall below catches the Lua exception
  -- cleanly). Silence notify for the duration of the fetch; completion
  -- failures should degrade to "no candidates", not a visible error.
  local saved_notify = vim.notify
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.notify = function(...) end
  local ok, items = pcall(fetch)
  vim.notify = saved_notify
  if not ok or type(items) ~= "table" then
    return (entry and entry.items) or {}
  end

  local names = {}
  for _, item in ipairs(items) do
    local ok_name, name = pcall(to_name, item)
    if ok_name and type(name) == "string" and name ~= "" then
      names[#names + 1] = name
    end
  end

  list_cache[key] = { items = names, at = now }
  return names
end

---@internal
---@param list string[]
---@param arg_lead string
---@return string[]
local function prefix(list, arg_lead)
  if arg_lead == "" then
    return list
  end
  local out = {}
  for _, v in ipairs(list) do
    if v:sub(1, #arg_lead) == arg_lead then
      out[#out + 1] = v
    end
  end
  return out
end

composer.register_type("CONTAINER_ID", {
  validate = function(raw)
    return true, raw, nil
  end,
  complete = function(arg_lead)
    -- Stays synchronous on purpose: Neovim's cmdline completion API wants the
    -- candidate list as a return value, so there is nowhere for a callback to
    -- deliver into. `cached_names` keeps it to one `ps -a` per TTL rather than
    -- one per <Tab>. list_containers' optional on_done is deliberately not
    -- passed here.
    local names = cached_names("containers", function()
      local engine = require("sandbox").get_engine()
      if not engine then
        return {}
      end
      return require("sandbox.core.usecases.containers.list_containers")(engine) or {}
    end, function(c)
      return c.name
    end)
    return prefix(names, arg_lead)
  end,
})

composer.register_type("IMAGE_ID", {
  validate = function(raw)
    return true, raw, nil
  end,
  complete = function(arg_lead)
    local names = cached_names("images", function()
      local engine = require("sandbox").get_engine()
      if not engine then
        return {}
      end
      return require("sandbox.core.usecases.images.list_images")(engine) or {}
    end, function(img)
      return img.repository .. ":" .. img.tag
    end)
    return prefix(names, arg_lead)
  end,
})

composer.register_type("VOLUME_NAME", {
  validate = function(raw)
    return true, raw, nil
  end,
  complete = function(arg_lead)
    local names = cached_names("volumes", function()
      local engine = require("sandbox").get_engine()
      if not engine then
        return {}
      end
      return require("sandbox.core.usecases.volumes.list_volumes")(engine) or {}
    end, function(v)
      return v.name
    end)
    return prefix(names, arg_lead)
  end,
})

composer.register_type("NETWORK_NAME", {
  validate = function(raw)
    return true, raw, nil
  end,
  complete = function(arg_lead)
    local names = cached_names("networks", function()
      local engine = require("sandbox").get_engine()
      if not engine then
        return {}
      end
      return require("sandbox.core.usecases.networks.list_networks")(engine) or {}
    end, function(n)
      return n.name
    end)
    return prefix(names, arg_lead)
  end,
})

composer.register_type("DISTRO_NAME", {
  validate = function(raw)
    return true, raw, nil
  end,
  complete = function(arg_lead)
    local names = cached_names("distros", function()
      return require("sandbox.core.usecases.wsl.list_distros")(require("sandbox.adapters.wsl.engine")) or {}
    end, function(d)
      return d.name
    end)
    return prefix(names, arg_lead)
  end,
})

local BUFFER_FLAG = { { name = "buffer", short = "b", bool = true } }

---@internal
---@param ctx table composer Ctx
---@return string[]|nil # nil when no command was given -- what the callers act on
local function command_tail(ctx)
  local out = {}
  if ctx.args.command then
    out[#out + 1] = ctx.args.command
  end
  for _, t in ipairs(ctx.rest) do
    out[#out + 1] = t
  end
  return #out > 0 and out or nil
end

---The working directory for an exec, from a `workdir=` kv.
---
--- `workdir=` rather than a positional: the command tail is free-form (every
--- token after the id is part of what runs inside the container), so a
--- positional could not be told apart from the command itself.
---@internal
---@param ctx table
---@return string|nil
local function exec_workdir(ctx)
  local w = ctx.kv and ctx.kv.workdir
  return (type(w) == "string" and w ~= "") and w or nil
end

---@internal
---@return table[]
local function container_routes()
  return {
    { path = { "container", "list" }, desc = "List all containers", run = container_cmds.list },

    {
      path = { "container", "logs" },
      args = { { name = "id", type = "CONTAINER_ID" } },
      desc = "Show logs of a container",
      run = function(ctx)
        container_cmds.logs(ctx.args.id)
      end,
    },

    {
      path = { "container", "logs-follow" },
      args = { { name = "id", type = "CONTAINER_ID" } },
      desc = "Stream a container's logs live (press q in the buffer to stop)",
      run = function(ctx)
        container_cmds.logs_follow(ctx.args.id)
      end,
    },

    {
      path = { "container", "exec" },
      args = {
        { name = "id", type = "CONTAINER_ID" },
        { name = "shell", type = "STRING", optional = true, values = { "sh", "bash", "zsh", "dash" } },
      },
      kv = { { key = "workdir", type = "STRING" } },
      desc = "Open a shell session inside a running container  [workdir=<path>]",
      run = function(ctx)
        container_cmds.exec(ctx.args.id, ctx.args.shell, exec_workdir(ctx))
      end,
    },

    {
      path = { "container", "exec-once" },
      args = {
        { name = "id", type = "CONTAINER_ID" },
        { name = "command", type = "STRING", optional = true },
      },
      kv = { { key = "workdir", type = "STRING" } },
      desc = "Run a one-off command inside a container (non-interactive)  [workdir=<path>]",
      run = function(ctx)
        container_cmds.exec_once(ctx.args.id, command_tail(ctx), exec_workdir(ctx))
      end,
    },

    {
      path = { "container", "start" },
      args = { { name = "id", type = "CONTAINER_ID" } },
      flags = BUFFER_FLAG,
      desc = "Start a stopped container (--buffer: stream to a terminal buffer)",
      run = function(ctx)
        if ctx.flags.buffer then
          container_buffer_cmds.start(ctx.args.id)
        else
          container_cmds.start(ctx.args.id)
        end
      end,
    },

    {
      path = { "container", "stop" },
      args = { { name = "id", type = "CONTAINER_ID" } },
      flags = BUFFER_FLAG,
      desc = "Stop a running container (--buffer: stream to a terminal buffer)",
      run = function(ctx)
        if ctx.flags.buffer then
          container_buffer_cmds.stop(ctx.args.id)
        else
          container_cmds.stop(ctx.args.id)
        end
      end,
    },

    {
      path = { "container", "kill" },
      args = { { name = "id", type = "CONTAINER_ID" } },
      flags = BUFFER_FLAG,
      desc = "Force kill a container (--buffer: stream to a terminal buffer)",
      run = function(ctx)
        if ctx.flags.buffer then
          container_buffer_cmds.kill(ctx.args.id)
        else
          container_cmds.kill(ctx.args.id)
        end
      end,
    },

    {
      path = { "container", "restart" },
      args = { { name = "id", type = "CONTAINER_ID" } },
      flags = BUFFER_FLAG,
      desc = "Restart a container (--buffer: stream to a terminal buffer)",
      run = function(ctx)
        if ctx.flags.buffer then
          container_buffer_cmds.restart(ctx.args.id)
        else
          container_cmds.restart(ctx.args.id)
        end
      end,
    },

    {
      path = { "container", "pause" },
      args = { { name = "id", type = "CONTAINER_ID" } },
      desc = "Pause a running container's processes",
      run = function(ctx)
        container_cmds.pause(ctx.args.id)
      end,
    },

    {
      path = { "container", "unpause" },
      args = { { name = "id", type = "CONTAINER_ID" } },
      desc = "Resume a paused container's processes",
      run = function(ctx)
        container_cmds.unpause(ctx.args.id)
      end,
    },

    {
      path = { "container", "rename" },
      args = {
        { name = "id", type = "CONTAINER_ID" },
        { name = "new_name", type = "STRING" },
      },
      desc = "Rename a container",
      run = function(ctx)
        container_cmds.rename(ctx.args.id, ctx.args.new_name)
      end,
    },

    {
      path = { "container", "stats" },
      args = { { name = "id", type = "CONTAINER_ID" } },
      desc = "Show a one-shot resource usage snapshot of a container",
      run = function(ctx)
        container_cmds.stats(ctx.args.id)
      end,
    },

    {
      path = { "container", "top" },
      args = { { name = "id", type = "CONTAINER_ID" } },
      desc = "List the processes running inside a container",
      run = function(ctx)
        container_cmds.top(ctx.args.id)
      end,
    },

    {
      path = { "container", "cp" },
      args = {
        { name = "src", type = "STRING" },
        { name = "dest", type = "STRING" },
      },
      desc = "Copy a file/directory between the host and a container (either side may be <id>:<path>)",
      run = function(ctx)
        container_cmds.cp(ctx.args.src, ctx.args.dest)
      end,
    },

    {
      path = { "container", "run" },
      desc = "Interactively create and start a new container (prompts for image, name, ports, volumes, env)",
      run = function(_ctx)
        container_cmds.run()
      end,
    },

    {
      path = { "container", "remove" },
      args = { { name = "id", type = "CONTAINER_ID" } },
      flags = BUFFER_FLAG,
      desc = "Remove a stopped container (--buffer: stream to a terminal buffer)",
      run = function(ctx)
        if ctx.flags.buffer then
          container_buffer_cmds.remove(ctx.args.id)
        else
          container_cmds.remove(ctx.args.id)
        end
      end,
    },

    {
      path = { "container", "prune" },
      flags = BUFFER_FLAG,
      desc = "Remove all stopped containers (--buffer: stream to a terminal buffer)",
      run = function(ctx)
        if ctx.flags.buffer then
          container_buffer_cmds.prune()
        else
          container_cmds.prune()
        end
      end,
    },

    {
      path = { "container", "inspect" },
      args = { { name = "id", type = "CONTAINER_ID" } },
      desc = "Inspect detailed information about a container",
      run = function(ctx)
        container_cmds.inspect(ctx.args.id)
      end,
    },
  }
end

---@internal
---@return table[]
local function image_routes()
  return {
    { path = { "image", "list" }, desc = "List all local images", run = image_cmds.list },

    {
      path = { "image", "pull" },
      args = { { name = "name", type = "STRING" } },
      flags = BUFFER_FLAG,
      desc = "Pull an image (--buffer: stream to a terminal buffer)",
      run = function(ctx)
        if ctx.flags.buffer then
          container_buffer_cmds.pull(ctx.args.name)
        else
          image_cmds.pull(ctx.args.name)
        end
      end,
    },

    {
      path = { "image", "push" },
      args = { { name = "name", type = "STRING" } },
      desc = "Push an image to a remote registry",
      run = function(ctx)
        image_cmds.push(ctx.args.name)
      end,
    },

    {
      path = { "image", "tag" },
      args = {
        { name = "source", type = "IMAGE_ID" },
        { name = "target", type = "STRING" },
      },
      desc = "Tag a local image with a new repository:tag",
      run = function(ctx)
        image_cmds.tag(ctx.args.source, ctx.args.target)
      end,
    },

    {
      path = { "image", "build" },
      args = {
        { name = "tag", type = "STRING" },
        { name = "path", type = "STRING", optional = true },
      },
      desc = "Build an image from a Dockerfile/Containerfile (streams to a terminal buffer)",
      run = function(ctx)
        container_buffer_cmds.build(ctx.args.tag, ctx.args.path)
      end,
    },

    {
      path = { "image", "save" },
      args = {
        { name = "image", type = "IMAGE_ID" },
        { name = "path", type = "STRING" },
      },
      desc = "Save (export) an image to a tarball on disk",
      run = function(ctx)
        image_cmds.save(ctx.args.image, ctx.args.path)
      end,
    },

    {
      path = { "image", "load" },
      args = { { name = "path", type = "STRING" } },
      desc = "Load (import) an image from a tarball on disk",
      run = function(ctx)
        image_cmds.load(ctx.args.path)
      end,
    },

    {
      path = { "image", "history" },
      args = { { name = "image", type = "IMAGE_ID" } },
      desc = "Show an image's layer history",
      run = function(ctx)
        image_cmds.history(ctx.args.image)
      end,
    },

    {
      path = { "image", "inspect" },
      args = { { name = "image", type = "IMAGE_ID" } },
      desc = "Inspect detailed information about an image",
      run = function(ctx)
        image_cmds.inspect(ctx.args.image)
      end,
    },

    {
      path = { "image", "remove" },
      args = { { name = "id", type = "IMAGE_ID" } },
      desc = "Remove a local image",
      run = function(ctx)
        image_cmds.remove(ctx.args.id)
      end,
    },

    {
      path = { "image", "prune" },
      flags = BUFFER_FLAG,
      desc = "Remove all dangling images (--buffer: stream to a terminal buffer)",
      run = function(ctx)
        if ctx.flags.buffer then
          container_buffer_cmds.image_prune()
        else
          image_cmds.prune()
        end
      end,
    },
  }
end

---@internal
---@return table[]
local function volume_routes()
  return {
    { path = { "volume", "list" }, desc = "List all local volumes", run = volume_cmds.list },

    {
      path = { "volume", "create" },
      args = { { name = "name", type = "STRING" } },
      desc = "Create a new named volume",
      run = function(ctx)
        volume_cmds.create(ctx.args.name)
      end,
    },

    {
      path = { "volume", "remove" },
      args = { { name = "name", type = "VOLUME_NAME" } },
      desc = "Remove a volume",
      run = function(ctx)
        volume_cmds.remove(ctx.args.name)
      end,
    },

    {
      path = { "volume", "inspect" },
      args = { { name = "name", type = "VOLUME_NAME" } },
      desc = "Inspect detailed information about a volume",
      run = function(ctx)
        volume_cmds.inspect(ctx.args.name)
      end,
    },

    {
      path = { "volume", "prune" },
      desc = "Remove all unused volumes",
      run = function(_ctx)
        volume_cmds.prune()
      end,
    },
  }
end

---@internal
---@return table[]
local function network_routes()
  return {
    { path = { "network", "list" }, desc = "List all local networks", run = network_cmds.list },

    {
      path = { "network", "create" },
      args = { { name = "name", type = "STRING" } },
      desc = "Create a new named network",
      run = function(ctx)
        network_cmds.create(ctx.args.name)
      end,
    },

    {
      path = { "network", "remove" },
      args = { { name = "name", type = "NETWORK_NAME" } },
      desc = "Remove a network",
      run = function(ctx)
        network_cmds.remove(ctx.args.name)
      end,
    },

    {
      path = { "network", "inspect" },
      args = { { name = "name", type = "NETWORK_NAME" } },
      desc = "Inspect detailed information about a network",
      run = function(ctx)
        network_cmds.inspect(ctx.args.name)
      end,
    },

    {
      path = { "network", "connect" },
      args = {
        { name = "network", type = "NETWORK_NAME" },
        { name = "id", type = "CONTAINER_ID" },
      },
      desc = "Connect a container to a network",
      run = function(ctx)
        network_cmds.connect(ctx.args.network, ctx.args.id)
      end,
    },

    {
      path = { "network", "disconnect" },
      args = {
        { name = "network", type = "NETWORK_NAME" },
        { name = "id", type = "CONTAINER_ID" },
      },
      desc = "Disconnect a container from a network",
      run = function(ctx)
        network_cmds.disconnect(ctx.args.network, ctx.args.id)
      end,
    },

    {
      path = { "network", "prune" },
      desc = "Remove all unused networks",
      run = function(_ctx)
        network_cmds.prune()
      end,
    },
  }
end

---@internal
---@return table[]
local function compose_routes()
  return {
    {
      path = { "compose", "up" },
      desc = "Start the compose project detected in cwd (detached)",
      run = function(_ctx)
        compose_cmds.up()
      end,
    },

    {
      path = { "compose", "down" },
      desc = "Stop and remove the compose project detected in cwd",
      run = function(_ctx)
        compose_cmds.down()
      end,
    },

    {
      path = { "compose", "restart" },
      desc = "Restart the compose project detected in cwd",
      run = function(_ctx)
        compose_cmds.restart()
      end,
    },

    {
      path = { "compose", "ps" },
      desc = "List services in the compose project detected in cwd",
      run = function(_ctx)
        compose_cmds.ps()
      end,
    },

    {
      path = { "compose", "logs" },
      desc = "Show logs for the compose project detected in cwd",
      run = function(_ctx)
        compose_cmds.logs()
      end,
    },
  }
end

---@internal
---@return table[]
local function wsl_routes()
  return {
    { path = { "wsl", "list" }, desc = "List all registered WSL distributions", run = wsl_cmds.list },

    {
      path = { "wsl", "start" },
      args = { { name = "name", type = "DISTRO_NAME" } },
      desc = "Start a WSL distro",
      run = function(ctx)
        wsl_cmds.start(ctx.args.name)
      end,
    },

    {
      path = { "wsl", "stop" },
      args = { { name = "name", type = "DISTRO_NAME" } },
      desc = "Stop (terminate) a WSL distro",
      run = function(ctx)
        wsl_cmds.stop(ctx.args.name)
      end,
    },

    {
      path = { "wsl", "exec" },
      args = {
        { name = "name", type = "DISTRO_NAME" },
        { name = "command", type = "STRING", optional = true },
      },
      desc = "Open a shell or run a command inside a WSL distro",
      run = function(ctx)
        wsl_cmds.exec(ctx.args.name, command_tail(ctx))
      end,
    },

    {
      path = { "wsl", "set-default" },
      args = { { name = "name", type = "DISTRO_NAME" } },
      desc = "Set a distro as the WSL default",
      run = function(ctx)
        wsl_cmds.set_default(ctx.args.name)
      end,
    },

    {
      path = { "wsl", "set-version" },
      args = {
        { name = "name", type = "DISTRO_NAME" },
        { name = "version", type = "STRING", values = { "1", "2" } },
      },
      desc = "Toggle a distro between WSL1/WSL2",
      run = function(ctx)
        wsl_cmds.set_version(ctx.args.name, ctx.args.version)
      end,
    },

    {
      path = { "wsl", "export" },
      args = {
        { name = "name", type = "DISTRO_NAME" },
        { name = "path", type = "STRING" },
      },
      desc = "Export a distro to a tarball on disk",
      run = function(ctx)
        wsl_cmds.export(ctx.args.name, ctx.args.path)
      end,
    },

    {
      path = { "wsl", "import" },
      args = {
        { name = "name", type = "STRING" },
        { name = "install_path", type = "STRING" },
        { name = "tar_path", type = "STRING" },
      },
      desc = "Import a distro from a tarball",
      run = function(ctx)
        wsl_cmds.import(ctx.args.name, ctx.args.install_path, ctx.args.tar_path)
      end,
    },

    {
      path = { "wsl", "shutdown-all" },
      desc = "Shut down the WSL2 VM and all running distros",
      run = function(_ctx)
        wsl_cmds.shutdown_all()
      end,
    },
  }
end

---@internal
---@return table[]
local function engine_routes()
  return {
    {
      path = { "engine", "set" },
      args = { { name = "name", type = "STRING", values = { "docker", "podman", "nerdctl" } } },
      desc = "Switch the active engine for this session",
      run = function(ctx)
        engine_cmds.set(ctx.args.name)
      end,
    },

    {
      path = { "engine", "get" },
      desc = "Show the currently active engine and why",
      run = function(_ctx)
        engine_cmds.get()
      end,
    },

    {
      path = { "engine", "reset" },
      desc = "Clear the session engine override, falling back to .sandboxrc/config",
      run = function(_ctx)
        engine_cmds.reset()
      end,
    },
  }
end

local GENERATED_DOCS_PATH = "docs/GENERATED_COMMANDS.md"

---@internal
---@return table[]
local function docs_routes()
  return {
    {
      path = { "docs", "generate" },
      desc = "Regenerate "
        .. GENERATED_DOCS_PATH
        .. " from the live route table, so "
        .. "docs/BINDINGS.md (hand-maintained) can be diffed against it to catch drift",
      run = function(_ctx)
        local notify = require("sandbox.notify")
        local ok, err = composer.document(GENERATED_DOCS_PATH)
        if not ok then
          notify.error("Failed to generate docs: " .. tostring(err))
          return
        end
        notify.info("Generated " .. GENERATED_DOCS_PATH)
      end,
    },
  }
end

---@internal
---@return table[]
local function devcontainer_routes()
  return {
    {
      path = { "devcontainer", "build" },
      desc = "Build/pull a .devcontainer/devcontainer.json's image and start a container from it",
      run = function(_ctx)
        devcontainer_cmds.build()
      end,
    },

    {
      path = { "devcontainer", "attach" },
      desc = "Open a shell in the running devcontainer for the project in cwd",
      run = function(_ctx)
        devcontainer_cmds.attach()
      end,
    },
  }
end

---@internal
---@return table[]
local function registry_routes()
  return {
    {
      path = { "registry", "login" },
      args = { { name = "registry", type = "STRING", optional = true } },
      desc = "Log in to a registry (prompts for username/password)",
      run = function(ctx)
        registry_cmds.login(ctx.args.registry)
      end,
    },

    {
      path = { "registry", "logout" },
      args = { { name = "registry", type = "STRING", optional = true } },
      desc = "Log out of a registry",
      run = function(ctx)
        registry_cmds.logout(ctx.args.registry)
      end,
    },
  }
end

---Register :Sandbox and its short alias :Sbx (same spec, two command names)
function M.setup()
  local routes = {}
  vim.list_extend(routes, container_routes())
  vim.list_extend(routes, image_routes())
  vim.list_extend(routes, volume_routes())
  vim.list_extend(routes, network_routes())
  vim.list_extend(routes, compose_routes())
  vim.list_extend(routes, engine_routes())
  vim.list_extend(routes, registry_routes())
  vim.list_extend(routes, docs_routes())
  vim.list_extend(routes, devcontainer_routes())

  -- WSL commands operate independently of the container engine and only
  -- make sense where wsl.exe is reachable -- matches the original guard in
  -- wsl_commands.lua, moved here since that file no longer self-registers.
  if wsl_cmds.available() then
    vim.list_extend(routes, wsl_routes())
  end

  local spec = {
    desc = "sandbox.nvim: container, image, volume, network, compose, and WSL distro operations (Docker/Podman)",
    routes = routes,
  }

  composer.verb("Sandbox", spec)
  composer.verb("Sbx", spec)
end

return M
