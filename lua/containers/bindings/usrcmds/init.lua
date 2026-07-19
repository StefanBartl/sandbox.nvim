---@module 'containers.bindings.usrcmds'
---@brief Registers :Container, :Image, and (when wsl.exe is reachable) :Wsl
--- -- three lib.nvim.usercmd.composer verbs replacing the 25 previously
--- independent flat commands (Container*, Container*Buffer, Image*,
--- ImagePullBuffer/ImagePruneBuffer, Wsl*).
---@description
--- Breaking change, no compat aliases. The 7 "*Buffer" terminal-output
--- variants (ContainerStartBuffer, ImagePullBuffer, ...) are folded into a
--- `--buffer`/`-b` flag on their base subcommand instead of separate
--- commands, e.g. `:Container start <id> --buffer` replaces
--- `:ContainerStartBuffer <id>` -- eliminates the near-duplicate handler
--- pairs (container_commands.lua vs container_commands_buffer.lua) that
--- differed only in output target.
---
--- <container-id>/<image-id>/<distro-name> args now complete dynamically
--- against the live engine (docker/podman/wsl), which the original flat
--- commands never did at all (no `complete` beyond `"file"` on the exec
--- commands). Each list call shells out synchronously
--- (run_argv.run_blocking_captured) with no built-in caching, so a naive
--- per-keystroke <Tab> would shell out repeatedly -- results are cached for
--- CACHE_TTL_MS per list kind, refreshed lazily on the next completion
--- request after expiry.

local composer = require("lib.nvim.usercmd.composer")

local container_cmds = require("containers.bindings.usrcmds.container_commands")
local container_buffer_cmds = require("containers.bindings.usrcmds.container_commands_buffer")
local image_cmds = require("containers.bindings.usrcmds.image_commands")
local wsl_cmds = require("containers.bindings.usrcmds.wsl_commands")

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
      local core = require("containers")
      return require("containers.core.usecases.containers.list_containers")(core.get_engine())
    end, function(c) return c.name end)
    return prefix(names, arg_lead)
  end,
})

composer.register_type("IMAGE_ID", {
  validate = function(raw) return true, raw, nil end,
  complete = function(arg_lead)
    local names = cached_names("images", function()
      local core = require("containers")
      return require("containers.core.usecases.images.list_images")(core.get_engine())
    end, function(img) return img.repository .. ":" .. img.tag end)
    return prefix(names, arg_lead)
  end,
})

composer.register_type("DISTRO_NAME", {
  validate = function(raw) return true, raw, nil end,
  complete = function(arg_lead)
    local names = cached_names("distros", function()
      return require("containers.core.usecases.wsl.list_distros")(require("containers.adapters.wsl.engine"))
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

---Register all user commands
function M.setup()
  composer.verb("Container", {
    desc = "Container operations (Docker/Podman)",
    routes = {
      { path = { "list" }, desc = "List all containers", run = container_cmds.list },

      { path = { "logs" },
        args = { { name = "id", type = "CONTAINER_ID" } },
        desc = "Show logs of a container",
        run = function(ctx) container_cmds.logs(ctx.args.id) end },

      { path = { "exec" },
        args = {
          { name = "id", type = "CONTAINER_ID" },
          { name = "shell", type = "STRING", optional = true, values = { "sh", "bash", "zsh", "dash" } },
        },
        desc = "Open a shell session inside a running container",
        run = function(ctx) container_cmds.exec(ctx.args.id, ctx.args.shell) end },

      { path = { "exec-once" },
        args = {
          { name = "id", type = "CONTAINER_ID" },
          { name = "command", type = "STRING", optional = true },
        },
        desc = "Run a one-off command inside a container (non-interactive)",
        run = function(ctx) container_cmds.exec_once(ctx.args.id, command_tail(ctx)) end },

      { path = { "start" },
        args = { { name = "id", type = "CONTAINER_ID" } },
        flags = BUFFER_FLAG,
        desc = "Start a stopped container (--buffer: stream to a terminal buffer)",
        run = function(ctx)
          if ctx.flags.buffer then container_buffer_cmds.start(ctx.args.id)
          else container_cmds.start(ctx.args.id) end
        end },

      { path = { "stop" },
        args = { { name = "id", type = "CONTAINER_ID" } },
        flags = BUFFER_FLAG,
        desc = "Stop a running container (--buffer: stream to a terminal buffer)",
        run = function(ctx)
          if ctx.flags.buffer then container_buffer_cmds.stop(ctx.args.id)
          else container_cmds.stop(ctx.args.id) end
        end },

      { path = { "kill" },
        args = { { name = "id", type = "CONTAINER_ID" } },
        flags = BUFFER_FLAG,
        desc = "Force kill a container (--buffer: stream to a terminal buffer)",
        run = function(ctx)
          if ctx.flags.buffer then container_buffer_cmds.kill(ctx.args.id)
          else container_cmds.kill(ctx.args.id) end
        end },

      { path = { "remove" },
        args = { { name = "id", type = "CONTAINER_ID" } },
        flags = BUFFER_FLAG,
        desc = "Remove a stopped container (--buffer: stream to a terminal buffer)",
        run = function(ctx)
          if ctx.flags.buffer then container_buffer_cmds.remove(ctx.args.id)
          else container_cmds.remove(ctx.args.id) end
        end },

      { path = { "prune" },
        flags = BUFFER_FLAG,
        desc = "Remove all stopped containers (--buffer: stream to a terminal buffer)",
        run = function(ctx)
          if ctx.flags.buffer then container_buffer_cmds.prune()
          else container_cmds.prune() end
        end },

      { path = { "inspect" },
        args = { { name = "id", type = "CONTAINER_ID" } },
        desc = "Inspect detailed information about a container",
        run = function(ctx) container_cmds.inspect(ctx.args.id) end },
    },
  })

  composer.verb("Image", {
    desc = "Image operations (Docker/Podman)",
    routes = {
      { path = { "list" }, desc = "List all local images", run = image_cmds.list },

      { path = { "pull" },
        args = { { name = "name", type = "STRING" } },
        flags = BUFFER_FLAG,
        desc = "Pull an image (--buffer: stream to a terminal buffer)",
        run = function(ctx)
          if ctx.flags.buffer then container_buffer_cmds.pull(ctx.args.name)
          else image_cmds.pull(ctx.args.name) end
        end },

      { path = { "remove" },
        args = { { name = "id", type = "IMAGE_ID" } },
        desc = "Remove a local image",
        run = function(ctx) image_cmds.remove(ctx.args.id) end },

      { path = { "prune" },
        flags = BUFFER_FLAG,
        desc = "Remove all dangling images (--buffer: stream to a terminal buffer)",
        run = function(ctx)
          if ctx.flags.buffer then container_buffer_cmds.image_prune()
          else image_cmds.prune() end
        end },
    },
  })

  -- WSL commands operate independently of the container engine and only
  -- make sense where wsl.exe is reachable -- matches the original guard in
  -- wsl_commands.lua, moved here since that file no longer self-registers.
  if wsl_cmds.available() then
    composer.verb("Wsl", {
      desc = "WSL distro management",
      routes = {
        { path = { "list" }, desc = "List all registered WSL distributions", run = wsl_cmds.list },

        { path = { "start" },
          args = { { name = "name", type = "DISTRO_NAME" } },
          desc = "Start a WSL distro",
          run = function(ctx) wsl_cmds.start(ctx.args.name) end },

        { path = { "stop" },
          args = { { name = "name", type = "DISTRO_NAME" } },
          desc = "Stop (terminate) a WSL distro",
          run = function(ctx) wsl_cmds.stop(ctx.args.name) end },

        { path = { "exec" },
          args = {
            { name = "name", type = "DISTRO_NAME" },
            { name = "command", type = "STRING", optional = true },
          },
          desc = "Open a shell or run a command inside a WSL distro",
          run = function(ctx) wsl_cmds.exec(ctx.args.name, command_tail(ctx)) end },
      },
    })
  end
end

return M
