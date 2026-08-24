---@module 'sandbox.bindings.usrcmds.engine_commands'
---@brief Runtime engine switching -- flip the active engine for the rest of
--- this Neovim session (`:Sandbox engine set docker|podman|nerdctl`) instead of only
--- at `setup({})` time, useful on a machine with both installed. Takes
--- precedence over the per-project `.sandboxrc` override and the
--- configured/detected default (see `sandbox.resolve_engine_name`).

local notify = require("sandbox.notify")
local M = {}

local VALID_ENGINES = { docker = true, podman = true, nerdctl = true }

--- Switch the active engine for the rest of this session.
---@param name string
function M.set(name)
  if not VALID_ENGINES[name] then
    notify.warn("Usage: :Sandbox engine set docker|podman|nerdctl")
    return
  end
  vim.g.sandbox_engine = name
  notify.info("Active engine set to " .. name .. " for this session")
end

--- The engines this session may switch between, in a fixed order.
---
--- Declared rather than derived from `VALID_ENGINES`, whose `pairs` order is
--- nondeterministic -- cycling has to land in the same place every time.
---@type string[]
M.ENGINES = { "docker", "podman", "nerdctl" }

--- Advance to the next engine in the cycle.
---
--- This is what the list views bind: reaching `:Sandbox engine set podman`
--- from a container list meant leaving the list, typing the command and
--- opening the list again, which is three steps for a thing you do while
--- looking at the very buffer that would change.
---@return string name  the engine now active
function M.cycle()
  local current = require("sandbox").resolve_engine_name()
  local idx = 1
  for i, name in ipairs(M.ENGINES) do
    if name == current then
      idx = i
      break
    end
  end
  local next_name = M.ENGINES[(idx % #M.ENGINES) + 1]
  M.set(next_name)
  return next_name
end

--- Clear the session-level override, falling back to .sandboxrc/config.
function M.reset()
  vim.g.sandbox_engine = nil
  notify.info("Session engine override cleared; using " .. tostring(require("sandbox").resolve_engine_name()))
end

--- Show which engine is currently active and why.
function M.get()
  local name = require("sandbox").resolve_engine_name()
  local source = "config"
  if vim.g.sandbox_engine then
    source = "session override (:Sandbox engine set)"
  elseif require("sandbox.util.project_config").read_engine_override() then
    source = ".sandboxrc"
  end
  notify.info("Active engine: " .. tostring(name) .. " (" .. source .. ")")
end

return M
