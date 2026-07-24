---@module 'sandbox.bindings.usrcmds.network_commands'
---@brief Network operation handlers (list, create, remove, inspect,
--- connect, disconnect, prune) using the active container engine
--- (Docker/Podman).
---@description
--- Exported as plain functions rather than registering commands directly, so
--- the "network" sub-namespace of the :Sandbox/:Sbx composer verb
--- (bindings/usrcmds/init.lua) can build typed routes + <Tab> completion
--- around them, matching container_commands.lua/image_commands.lua/
--- volume_commands.lua.

local notify = require("sandbox.notify")
local friendly_error = require("sandbox.util.friendly_error")
local confirm = require("sandbox.util.confirm")
local M = {}

--- List all local networks
function M.list()
  local engine = require("sandbox").get_engine()
  if not engine then
    return
  end

  local usecase = require("sandbox.core.usecases.networks.list_networks")
  local networks, err = usecase(engine)
  if not networks then
    notify.error("Failed to list networks: " .. friendly_error(err), { err = err })
    return
  end

  if err then
    notify.warn("Some networks could not be parsed: " .. friendly_error(err), { err = err })
  end

  local view = require("sandbox.ui.network_list_view")
  view(networks)
end

--- Create a new named network
---@param name string
function M.create(name)
  if not name or name == "" then
    notify.warn("Usage: :Sandbox network create <name>")
    return
  end

  local engine = require("sandbox").get_engine()
  if not engine then
    return
  end

  local usecase = require("sandbox.core.usecases.networks.create_network")
  local ok, err = usecase(engine, name)
  if not ok then
    notify.error("Failed to create network " .. name .. ": " .. friendly_error(err), { name = name, err = err })
    return
  end

  notify.info("Network created: " .. name)
end

--- Remove a network
---@param name string
function M.remove(name)
  if not name or name == "" then
    notify.warn("Usage: :Sandbox network remove <name>")
    return
  end

  local engine = require("sandbox").get_engine()
  if not engine then
    return
  end

  confirm.destructive("Remove network " .. name .. "?", function()
    local usecase = require("sandbox.core.usecases.networks.remove_network")
    usecase(engine, name, function(ok, err)
      if ok then
        notify.info("Network removed: " .. name)
      else
        notify.error("Failed to remove network " .. name .. ": " .. friendly_error(err), { name = name, err = err })
      end
    end)
  end)
end

--- Inspect detailed information about a network
---@param name string
function M.inspect(name)
  if not name or name == "" then
    notify.warn("Usage: :Sandbox network inspect <name>")
    return
  end

  local engine = require("sandbox").get_engine()
  if not engine then
    return
  end

  local usecase = require("sandbox.core.usecases.networks.inspect_network")
  local view = require("sandbox.ui.inspect_view")

  local ok, result = pcall(usecase, engine, name)
  if not ok then
    notify.error("Failed to inspect network " .. name .. ": " .. tostring(result), { name = name, err = result })
    return
  end

  view(result, "network-" .. name)
end

--- Connect a container to a network
---@param network string
---@param container_id string
function M.connect(network, container_id)
  if not network or network == "" or not container_id or container_id == "" then
    notify.warn("Usage: :Sandbox network connect <network> <container-id>")
    return
  end

  local engine = require("sandbox").get_engine()
  if not engine then
    return
  end

  local usecase = require("sandbox.core.usecases.networks.connect_network")
  local ok, err = usecase(engine, network, container_id)
  if not ok then
    notify.error(
      "Failed to connect " .. container_id .. " to " .. network .. ": " .. friendly_error(err),
      { network = network, container_id = container_id, err = err }
    )
    return
  end

  notify.info("Connected " .. container_id .. " to network " .. network)
end

--- Disconnect a container from a network
---@param network string
---@param container_id string
function M.disconnect(network, container_id)
  if not network or network == "" or not container_id or container_id == "" then
    notify.warn("Usage: :Sandbox network disconnect <network> <container-id>")
    return
  end

  local engine = require("sandbox").get_engine()
  if not engine then
    return
  end

  local usecase = require("sandbox.core.usecases.networks.disconnect_network")
  local ok, err = usecase(engine, network, container_id)
  if not ok then
    notify.error(
      "Failed to disconnect " .. container_id .. " from " .. network .. ": " .. friendly_error(err),
      { network = network, container_id = container_id, err = err }
    )
    return
  end

  notify.info("Disconnected " .. container_id .. " from network " .. network)
end

--- Remove all unused networks
function M.prune()
  local engine = require("sandbox").get_engine()
  if not engine then
    return
  end

  confirm.destructive("Prune all unused networks?", function()
    local usecase = require("sandbox.core.usecases.networks.prune_networks")
    usecase(engine, function(ok, err)
      if ok then
        notify.info("All unused networks pruned successfully!")
      else
        notify.error("Failed to prune networks: " .. friendly_error(err), { err = err })
      end
    end)
  end)
end

return M
