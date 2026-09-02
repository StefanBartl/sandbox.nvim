---@module 'sandbox'
--- Entry point for the plugin

local config = require("sandbox.config")
local notify = require("sandbox.notify")

local engines = {
  podman = require("sandbox.adapters.podman.engine"),
  docker = require("sandbox.adapters.docker.engine"),
  nerdctl = require("sandbox.adapters.nerdctl.engine"),
}

local compose_engines = {
  podman = require("sandbox.adapters.podman.compose_engine"),
  docker = require("sandbox.adapters.docker.compose_engine"),
  nerdctl = require("sandbox.adapters.nerdctl.compose_engine"),
}

local M = {}

--- Setup the plugin
--- @param opts table|nil: Optional user configuration
function M.setup(opts)
  config.setup(opts)

  -- Tell hover.nvim what an image reference under the cursor is. Soft: no
  -- hover.nvim, nothing happens; and nothing is registered against a
  -- hover.nvim that would ask on every trigger. `hover = false` turns it off.
  if config.options.hover ~= false then
    require("sandbox.hover").setup()
  end
end

--- Resolve the active engine name. Precedence: a runtime session override
--- set via `:Sandbox engine set docker|podman` (`vim.g.sandbox_engine`) >
--- a per-project `.sandboxrc` override (see `util/project_config.lua`) >
--- an engine named in `setup` > detection.
---
--- **The three overrides are instructions and are obeyed as written.** Only
--- the last step is a guess, and only that step asks whether the engine can
--- answer: detection used to pick the first CLI on `PATH`, which on a machine
--- with Podman Desktop installed but its VM stopped meant every call failed
--- after ~370 ms while a running Docker engine was never asked. Being
--- installed is not being able to answer, and `engine_utils.get_live_engine`
--- is that distinction.
---
--- The probe costs one process start per installed engine, once per session
--- (`engine_utils.forget` clears it). It is paid here rather than in `setup`
--- so a Neovim start that never touches a container pays nothing.
--- @return Sandbox.Engine|nil
function M.resolve_engine_name()
  if vim.g.sandbox_engine then
    return vim.g.sandbox_engine
  end
  local project_engine = require("sandbox.util.project_config").read_engine_override()
  if project_engine then
    return project_engine
  end
  if config.engine_named then
    return config.options.engine
  end
  return require("sandbox.engine_utils").get_live_engine()
end

--- Get the active engine implementation
--- @return table|nil
function M.get_engine()
  local name = M.resolve_engine_name()
  local engine = engines[name]
  if not engine then
    notify.error("Invalid engine: " .. tostring(name))
    return nil
  end
  return engine
end

--- Get the active ComposeEngine implementation
--- @return table|nil
function M.get_compose_engine()
  local name = M.resolve_engine_name()
  local engine = compose_engines[name]
  if not engine then
    notify.error("Invalid engine: " .. tostring(name))
    return nil
  end
  return engine
end

return M
