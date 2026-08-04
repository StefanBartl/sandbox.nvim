---@module 'sandbox.statusline'
---@brief Ambient "engine (running/total)" summary for a statusline plugin
--- (lualine, heirline, or the native statusline via `%{v:lua...}`), for
--- people who want to know "is anything running" without opening a list
--- view. Plain Lua string return, no hard dependency on any statusline
--- plugin -- lua/sandbox/README.md-equivalent soft-dependency philosophy.
---@description
--- Result is cached for STATUS_CACHE_TTL_MS so a statusline redrawing many
--- times a second doesn't shell out to `docker ps`/`podman ps` on every
--- redraw. Any failure (daemon down, no engine configured) degrades to an
--- empty string rather than erroring or notifying -- a statusline is not
--- the place for error popups.

local M = {}

local STATUS_CACHE_TTL_MS = 3000
---@type { text: string, at: integer }|nil
local cache = nil

---@internal
---@return string
local function compute()
  local sandbox = require("sandbox")
  local engine_name = sandbox.resolve_engine_name()
  if not engine_name then
    return ""
  end

  local engine = sandbox.get_engine()
  if not engine then
    return ""
  end

  local ok, containers = pcall(engine.list_containers)
  if not ok or not containers then
    return engine_name
  end

  local highlights = require("sandbox.ui.highlights")
  local running = 0
  for _, c in ipairs(containers) do
    if highlights.group_for_status(c.status) == "SandboxStatusRunning" then
      running = running + 1
    end
  end

  return string.format("%s (%d/%d)", engine_name, running, #containers)
end

--- Ambient "engine (running/total)" summary, e.g. "docker (2/5)".
--- Cached for STATUS_CACHE_TTL_MS; returns "" on any failure.
---@return string
function M.status()
  local now = vim.uv.now()
  if cache and (now - cache.at) < STATUS_CACHE_TTL_MS then
    return cache.text
  end

  local ok, text = pcall(compute)
  text = (ok and text) or ""
  cache = { text = text, at = now }
  return text
end

--- Ready-made lualine component function. Usage:
---   require("lualine").setup({
---     sections = { lualine_x = { require("sandbox.statusline").lualine_component } },
---   })
M.lualine_component = M.status

return M
