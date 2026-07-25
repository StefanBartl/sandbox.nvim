---@module 'sandbox.bindings.usrcmds.engine_commands'
---@brief Runtime engine switching -- flip the active engine for the rest of
--- this Neovim session (`:Sandbox engine set docker|podman`) instead of only
--- at `setup({})` time, useful on a machine with both installed. Takes
--- precedence over the per-project `.sandboxrc` override and the
--- configured/detected default (see `sandbox.resolve_engine_name`).

local notify = require("sandbox.notify")
local M = {}

local VALID_ENGINES = { docker = true, podman = true }

--- Switch the active engine for the rest of this session.
---@param name string
function M.set(name)
  if not VALID_ENGINES[name] then
    notify.warn("Usage: :Sandbox engine set docker|podman")
    return
  end
  vim.g.sandbox_engine = name
  notify.info("Active engine set to " .. name .. " for this session")
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
