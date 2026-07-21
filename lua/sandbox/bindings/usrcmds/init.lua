---@module 'sandbox.bindings.usrcmds'
---@brief Registers :Sandbox (and its short alias :Sbx) -- a single
--- lib.nvim.usercmd.composer verb with three sub-namespaces (container,
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
--- cached for CACHE_TTL_MS per list kind, refreshed lazily on the next
--- completion request after expiry.

local composer = require("lib.nvim.usercmd.composer")

local container_cmds = require("sandbox.bindings.usrcmds.container_commands")
local container_buffer_cmds = require("sandbox.bindings.usrcmds.container_commands_buffer")
local image_cmds = require("sandbox.bindings.usrcmds.image_commands")
local wsl_cmds = require("sandbox.bindings.usrcmds.wsl_commands")

local M = {}

-- ── Cached dynamic completion ────────────────────────────────────────────

local CACHE_TTL_MS = 4000
---@type table<string, { items: string[], at: integer }>
local list_cache = {}

---@param key string
---@param fetch fun(): table[]
---@param to_name fun(item: table): string
---@return string[]
local function cached_names(key, fetch, to_name)
  local now = vim.loop.now()
  local entry = list_cache[key]
  if entry and (now - entry.at) < CACHE_TTL_MS then
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
  vim.notify = function() end
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
  validate = function(raw) return true, raw, nil end,
  complete = function(arg_lead)
    local names = cached_names("containers", function()
      local core = require("sandbox")
      return require("sandbox.core.usecases.containers.list_containers")(core.get_engine())
    end, function(c) return c.name end)
    return prefix(names, arg_lead)
  end,
})

composer.register_type("IMAGE_ID", {
  validate = function(raw) return true, raw, nil end,
  complete = function(arg_lead)
    local names = cached_names("images", function()
      local core = require("sandbox")
      return require("sandbox.core.usecases.images.list_images")(core.get_engine())
    end, function(img) return img.repository .. ":" .. img.tag end)
    return prefix(names, arg_lead)
  end,
})

composer.register_type("DISTRO_NAME", {
  validate = function(raw) return true, raw, nil end,
  complete = function(arg_lead)
    local names = cached_names("distros", function()
      return require("sandbox.core.usecases.wsl.list_distros")(require("sandbox.adapters.wsl.engine"))
    end, function(d) return d.name end)
    return prefix(names, arg_lead)
  end,
})

local BUFFER_FLAG = { { name = "buffer", short = "b", bool = true } }

---@param ctx table composer Ctx
---@return string[]
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

---@return table[]
local function container_routes()
  return {
    { path = { "container", "list" }, desc = "List all containers", run = container_cmds.list },

    { path = { "container", "logs" },
      args = { { name = "id", type = "CONTAINER_ID" } },
      desc = "Show logs of a container",
      run = function(ctx) container_cmds.logs(ctx.args.id) end },

    { path = { "container", "exec" },
      args = {
        { name = "id", type = "CONTAINER_ID" },
        { name = "shell", type = "STRING", optional = true, values = { "sh", "bash", "zsh", "dash" } },
      },
      desc = "Open a shell session inside a running container",
      run = function(ctx) container_cmds.exec(ctx.args.id, ctx.args.shell) end },

    { path = { "container", "exec-once" },
      args = {
        { name = "id", type = "CONTAINER_ID" },
        { name = "command", type = "STRING", optional = true },
      },
      desc = "Run a one-off command inside a container (non-interactive)",
      run = function(ctx) container_cmds.exec_once(ctx.args.id, command_tail(ctx)) end },

    { path = { "container", "start" },
      args = { { name = "id", type = "CONTAINER_ID" } },
      flags = BUFFER_FLAG,
      desc = "Start a stopped container (--buffer: stream to a terminal buffer)",
      run = function(ctx)
        if ctx.flags.buffer then container_buffer_cmds.start(ctx.args.id)
        else container_cmds.start(ctx.args.id) end
      end },

    { path = { "container", "stop" },
      args = { { name = "id", type = "CONTAINER_ID" } },
      flags = BUFFER_FLAG,
      desc = "Stop a running container (--buffer: stream to a terminal buffer)",
      run = function(ctx)
        if ctx.flags.buffer then container_buffer_cmds.stop(ctx.args.id)
        else container_cmds.stop(ctx.args.id) end
      end },

    { path = { "container", "kill" },
      args = { { name = "id", type = "CONTAINER_ID" } },
      flags = BUFFER_FLAG,
      desc = "Force kill a container (--buffer: stream to a terminal buffer)",
      run = function(ctx)
        if ctx.flags.buffer then container_buffer_cmds.kill(ctx.args.id)
        else container_cmds.kill(ctx.args.id) end
      end },

    { path = { "container", "remove" },
      args = { { name = "id", type = "CONTAINER_ID" } },
      flags = BUFFER_FLAG,
      desc = "Remove a stopped container (--buffer: stream to a terminal buffer)",
      run = function(ctx)
        if ctx.flags.buffer then container_buffer_cmds.remove(ctx.args.id)
        else container_cmds.remove(ctx.args.id) end
      end },

    { path = { "container", "prune" },
      flags = BUFFER_FLAG,
      desc = "Remove all stopped containers (--buffer: stream to a terminal buffer)",
      run = function(ctx)
        if ctx.flags.buffer then container_buffer_cmds.prune()
        else container_cmds.prune() end
      end },

    { path = { "container", "inspect" },
      args = { { name = "id", type = "CONTAINER_ID" } },
      desc = "Inspect detailed information about a container",
      run = function(ctx) container_cmds.inspect(ctx.args.id) end },
  }
end

---@return table[]
local function image_routes()
  return {
    { path = { "image", "list" }, desc = "List all local images", run = image_cmds.list },

    { path = { "image", "pull" },
      args = { { name = "name", type = "STRING" } },
      flags = BUFFER_FLAG,
      desc = "Pull an image (--buffer: stream to a terminal buffer)",
      run = function(ctx)
        if ctx.flags.buffer then container_buffer_cmds.pull(ctx.args.name)
        else image_cmds.pull(ctx.args.name) end
      end },

    { path = { "image", "remove" },
      args = { { name = "id", type = "IMAGE_ID" } },
      desc = "Remove a local image",
      run = function(ctx) image_cmds.remove(ctx.args.id) end },

    { path = { "image", "prune" },
      flags = BUFFER_FLAG,
      desc = "Remove all dangling images (--buffer: stream to a terminal buffer)",
      run = function(ctx)
        if ctx.flags.buffer then container_buffer_cmds.image_prune()
        else image_cmds.prune() end
      end },
  }
end

---@return table[]
local function wsl_routes()
  return {
    { path = { "wsl", "list" }, desc = "List all registered WSL distributions", run = wsl_cmds.list },

    { path = { "wsl", "start" },
      args = { { name = "name", type = "DISTRO_NAME" } },
      desc = "Start a WSL distro",
      run = function(ctx) wsl_cmds.start(ctx.args.name) end },

    { path = { "wsl", "stop" },
      args = { { name = "name", type = "DISTRO_NAME" } },
      desc = "Stop (terminate) a WSL distro",
      run = function(ctx) wsl_cmds.stop(ctx.args.name) end },

    { path = { "wsl", "exec" },
      args = {
        { name = "name", type = "DISTRO_NAME" },
        { name = "command", type = "STRING", optional = true },
      },
      desc = "Open a shell or run a command inside a WSL distro",
      run = function(ctx) wsl_cmds.exec(ctx.args.name, command_tail(ctx)) end },
  }
end

---Register :Sandbox and its short alias :Sbx (same spec, two command names)
function M.setup()
  local routes = {}
  vim.list_extend(routes, container_routes())
  vim.list_extend(routes, image_routes())

  -- WSL commands operate independently of the container engine and only
  -- make sense where wsl.exe is reachable -- matches the original guard in
  -- wsl_commands.lua, moved here since that file no longer self-registers.
  if wsl_cmds.available() then
    vim.list_extend(routes, wsl_routes())
  end

  local spec = {
    desc = "sandbox.nvim: container, image, and WSL distro operations (Docker/Podman)",
    routes = routes,
  }

  composer.verb("Sandbox", spec)
  composer.verb("Sbx", spec)
end

return M
