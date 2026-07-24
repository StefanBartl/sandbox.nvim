---@module 'sandbox.bindings.usrcmds.volume_commands'
---@brief Volume operation handlers (list, create, remove, inspect, prune)
--- using the active container engine (Docker/Podman).
---@description
--- Exported as plain functions rather than registering commands directly, so
--- the "volume" sub-namespace of the :Sandbox/:Sbx composer verb
--- (bindings/usrcmds/init.lua) can build typed routes + <Tab> completion
--- around them, matching container_commands.lua/image_commands.lua.

local notify = require("sandbox.notify")
local friendly_error = require("sandbox.util.friendly_error")
local confirm = require("sandbox.util.confirm")
local M = {}

--- List all local volumes
function M.list()
  local engine = require("sandbox").get_engine()
  if not engine then
    return
  end

  local usecase = require("sandbox.core.usecases.volumes.list_volumes")
  local volumes, err = usecase(engine)
  if not volumes then
    notify.error("Failed to list volumes: " .. friendly_error(err), { err = err })
    return
  end

  if err then
    notify.warn("Some volumes could not be parsed: " .. friendly_error(err), { err = err })
  end

  local view = require("sandbox.ui.volume_list_view")
  view(volumes)
end

--- Create a new named volume
---@param name string
function M.create(name)
  if not name or name == "" then
    notify.warn("Usage: :Sandbox volume create <name>")
    return
  end

  local engine = require("sandbox").get_engine()
  if not engine then
    return
  end

  local usecase = require("sandbox.core.usecases.volumes.create_volume")
  local ok, err = usecase(engine, name)
  if not ok then
    notify.error("Failed to create volume " .. name .. ": " .. friendly_error(err), { name = name, err = err })
    return
  end

  notify.info("Volume created: " .. name)
end

--- Remove a volume
---@param name string
function M.remove(name)
  if not name or name == "" then
    notify.warn("Usage: :Sandbox volume remove <name>")
    return
  end

  local engine = require("sandbox").get_engine()
  if not engine then
    return
  end

  confirm.destructive("Remove volume " .. name .. "?", function()
    local usecase = require("sandbox.core.usecases.volumes.remove_volume")
    usecase(engine, name, function(ok, err)
      if ok then
        notify.info("Volume removed: " .. name)
      else
        notify.error("Failed to remove volume " .. name .. ": " .. friendly_error(err), { name = name, err = err })
      end
    end)
  end)
end

--- Inspect detailed information about a volume
---@param name string
function M.inspect(name)
  if not name or name == "" then
    notify.warn("Usage: :Sandbox volume inspect <name>")
    return
  end

  local engine = require("sandbox").get_engine()
  if not engine then
    return
  end

  local usecase = require("sandbox.core.usecases.volumes.inspect_volume")
  local view = require("sandbox.ui.inspect_view")

  local ok, result = pcall(usecase, engine, name)
  if not ok then
    notify.error("Failed to inspect volume " .. name .. ": " .. tostring(result), { name = name, err = result })
    return
  end

  view(result, "volume-" .. name)
end

--- Remove all unused volumes
function M.prune()
  local engine = require("sandbox").get_engine()
  if not engine then
    return
  end

  confirm.destructive("Prune all unused volumes?", function()
    local usecase = require("sandbox.core.usecases.volumes.prune_volumes")
    usecase(engine, function(ok, err)
      if ok then
        notify.info("All unused volumes pruned successfully!")
      else
        notify.error("Failed to prune volumes: " .. friendly_error(err), { err = err })
      end
    end)
  end)
end

return M
