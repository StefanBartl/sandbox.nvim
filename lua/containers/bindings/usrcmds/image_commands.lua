---@module 'containers.bindings.usrcmds.image_commands'
---@brief Image operation handlers (list, pull, remove, prune) using the
--- active container engine (Docker/Podman).
---@description
--- Exported as plain functions rather than registering commands directly, so
--- lib.nvim.usercmd.composer's :Image verb (bindings/usrcmds/init.lua) can
--- build typed routes + <Tab> completion around them. Each function's own
--- body is unchanged from before the composer migration; only the
--- registration site moved.

local notify = require("containers.notify")
local friendly_error = require("containers.util.friendly_error")
local M = {}

--- List all available images
function M.list()
  local config = require("containers.config")
  local engine = require("containers").get_engine()
  if not engine then
    return
  end

  local usecase = require("containers.core.usecases.images.list_images")
  local images, err = usecase(engine)
  if not images then
    notify.error("Failed to list images: " .. friendly_error(err), { err = err })
    return
  end

  if err then
    notify.warn("Some images could not be parsed: " .. friendly_error(err), { err = err })
  end

  local view
  if config.options.engine == "docker" then
    view = require("containers.ui.image_list_view_docker")
  elseif config.options.engine == "podman" then
    view = require("containers.ui.image_list_view_podman")
  else
    notify.error("Unknown engine: " .. tostring(config.options.engine))
    return
  end

  view(images)
end

--- Pull a specific image by name
---@param image string
function M.pull(image)
  if not image or image == "" then
    notify.warn("Usage: :Image pull <image>")
    return
  end

  local engine = require("containers").get_engine()
  if not engine then
    return
  end

  local usecase = require("containers.core.usecases.images.pull_image")
  local ok, err = usecase(engine, image)
  if not ok then
    notify.error("Failed to pull image " .. image .. ": " .. friendly_error(err), { image = image, err = err })
    return
  end

  notify.info("Image pulled successfully: " .. image)
end

--- Remove a specific image by ID
---@param id string
function M.remove(id)
  if not id or id == "" then
    notify.warn("Usage: :Image remove <image-id>")
    return
  end

  local engine = require("containers").get_engine()
  if not engine then
    return
  end

  local usecase = require("containers.core.usecases.images.remove_image")
  usecase(engine, id, function(ok, err)
    if ok then
      notify.info("Image removed successfully: " .. id)
    else
      notify.error("Failed to remove image " .. id .. ": " .. friendly_error(err), { id = id, err = err })
    end
  end)
end

--- Prune (remove) all dangling images
function M.prune()
  local engine = require("containers").get_engine()
  if not engine then
    return
  end

  local usecase = require("containers.core.usecases.images.prune_images")
  usecase(engine, function(ok, err)
    if ok then
      notify.info("All dangling images pruned successfully!")
    else
      notify.error("Failed to prune images: " .. friendly_error(err), { err = err })
    end
  end)
end

return M
