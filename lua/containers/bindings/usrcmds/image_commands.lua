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
local M = {}

--- List all available images
function M.list()
  local core = require("containers")
  local config = require("containers.config")
  local engine = core.get_engine()
  local usecase = require("containers.core.usecases.images.list_images")

  local ok, result = pcall(usecase, engine)
  if not ok then
    notify.error("Failed to list images: " .. result)
    return
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

  view(result)
end

--- Pull a specific image by name
---@param image string
function M.pull(image)
  if not image or image == "" then
    notify.warn("Usage: :Image pull <image>")
    return
  end

  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.images.pull_image")

  local ok, err = pcall(usecase, engine, image)
  if not ok then
    notify.error("Failed to pull image: " .. err)
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
  local usecase = require("containers.core.usecases.images.remove_image")

  local ok, err = pcall(usecase, engine, id)
  if not ok then
    notify.error("Failed to remove image: " .. err)
    return
  end

  notify.info("Image removed successfully: " .. id)
end

--- Prune (remove) all dangling images
function M.prune()
  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.images.prune_images")

  local ok, err = pcall(usecase, engine)
  if not ok then
    notify.error("Failed to prune images: " .. err)
    return
  end

  notify.info("All dangling images pruned successfully!")
end

return M
