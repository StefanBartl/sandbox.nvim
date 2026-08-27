---@module 'sandbox.statusline'
---@brief Ambient "engine (running/total)" summary for a statusline plugin
--- (lualine, heirline, or the native statusline via `%{v:lua...}`), for
--- people who want to know "is anything running" without opening a list
--- view. Plain Lua string return, no hard dependency on any statusline
--- plugin -- lua/sandbox/README.md-equivalent soft-dependency philosophy.
---@description
--- Result is cached for `status_cache_ttl_ms` so a statusline redrawing many
--- times a second doesn't shell out to `docker ps`/`podman ps` on every
--- redraw. Any failure (daemon down, no engine configured) degrades to an
--- empty string rather than erroring or notifying -- a statusline is not
--- the place for error popups.
---
--- The refresh itself is stale-while-revalidate: `M.status()` always returns
--- the cached text immediately and, when that text has gone stale, kicks off a
--- background `ps` whose result replaces the cache for the next redraw. It used
--- to call the engine synchronously, which meant a statusline component froze
--- Neovim for the length of a `docker ps` (100-500ms, appreciably more under
--- Docker Desktop on Windows) every `status_cache_ttl_ms`. The indicator is
--- suppressed for this call (`progress = false`): an ambient refresh every few
--- seconds would otherwise paint a permanent "docker ps" handle.
---
--- Not entirely free: spawning a process is synchronous up to the fork/exec, so
--- the redraw that triggers a refresh still pays ~10ms on Windows (measured;
--- the environment build next to it is under 1ms). That is once per
--- the TTL, against 100-500ms for the full round-trip before -- but
--- it is the reason to raise the TTL rather than lower it if the component ever
--- feels sticky.

local M = {}

---How long a statusline reading stays fresh, in ms.
---
---`status_cache_ttl_ms`: the dial between "the statusline is current" and
---"docker/podman is asked how often". On a slow daemon 3s is already too
---eager; on a local one it could be tighter.
---@return integer
local function ttl_ms()
  local ok, config = pcall(require, "sandbox.config")
  if not ok then
    return 3000
  end
  local n = (config.options or {}).status_cache_ttl_ms
  return (type(n) == "number" and n >= 0) and n or 3000
end
---@type { text: string, at: integer }|nil
local cache = nil

---@internal
---Format the summary line from a container list.
---@param engine_name string
---@param containers table[]
---@return string
local function format_summary(engine_name, containers)
  local highlights = require("sandbox.ui.highlights")
  local running = 0
  for _, c in ipairs(containers) do
    if highlights.group_for_status(c.status) == "SandboxStatusRunning" then
      running = running + 1
    end
  end

  return string.format("%s (%d/%d)", engine_name, running, #containers)
end

---@internal
---True while a background refresh is in flight, so a statusline redrawing many
---times a second cannot stack up one `ps` per redraw while the first is still
---running.
local refreshing = false

---@internal
---Start a background refresh of the cache. Never blocks, never notifies.
---@return nil
local function refresh()
  if refreshing then
    return
  end

  local sandbox = require("sandbox")
  local engine_name = sandbox.resolve_engine_name()
  if not engine_name then
    cache = { text = "", at = vim.uv.now() }
    return
  end

  local engine = sandbox.get_engine()
  if not engine then
    cache = { text = "", at = vim.uv.now() }
    return
  end

  refreshing = true

  -- pcall guards the *call*: an engine that does not implement
  -- list_containers throws synchronously (the port's error(...) stub).
  local ok_call = pcall(engine.list_containers, function(containers)
    refreshing = false
    cache = {
      text = containers and format_summary(engine_name, containers) or engine_name,
      at = vim.uv.now(),
    }
  end, { progress = false })

  if not ok_call then
    refreshing = false
    cache = { text = engine_name, at = vim.uv.now() }
  end
end

--- Ambient "engine (running/total)" summary, e.g. "docker (2/5)".
--- Cached for `status_cache_ttl_ms`; returns "" on any failure and never blocks.
---@return string
function M.status()
  local now = vim.uv.now()
  if not cache or (now - cache.at) >= ttl_ms() then
    refresh()
  end
  -- Stale value on the first redraw after expiry, correct one on the next --
  -- for an ambient summary that is the right trade against a frozen editor.
  return cache and cache.text or ""
end

--- Ready-made lualine component function. Usage:
---   require("lualine").setup({
---     sections = { lualine_x = { require("sandbox.statusline").lualine_component } },
---   })
M.lualine_component = M.status

return M
