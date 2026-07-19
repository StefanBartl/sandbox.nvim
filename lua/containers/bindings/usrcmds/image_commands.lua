---@module 'containers.bindings.usrcmds.image_commands'
---@brief Image operation handlers (list, pull, remove, prune) using the
--- active container engine (Docker/Podman).
---@description
--- Exported as plain functions rather than registering commands directly, so
--- lib.nvim.usercmd.composer's :Image verb (bindings/usrcmds/init.lua) can
--- build typed routes + <Tab> completion around them. Each function's own
--- body is unchanged from before the composer migration; only the
--- registration site moved.

local M = {}

--- List all available images
function M.list()
  local core = require("containers")
  local config = require("containers.config")
  local engine = core.get_engine()
  local usecase = require("containers.core.usecases.images.list_images")

  local ok, result = pcall(usecase, engine)
  if not ok then
    vim.notify("Failed to list images: " .. result, vim.log.levels.ERROR)
    return
  end

  local view
  if config.options.engine == "docker" then
    view = require("containers.ui.image_list_view_docker")
  elseif config.options.engine == "podman" then
    view = require("containers.ui.image_list_view_podman")
  else
    vim.notify("[nvim-containers] Unknown engine: " .. tostring(config.options.engine), vim.log.levels.ERROR)
    return
  end

  view(result)
end

--- Pull a specific image by name
---@param image string
function M.pull(image)
  if not image or image == "" then
    vim.notify("Usage: :Image pull <image>", vim.log.levels.WARN)
    return
  end

  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.images.pull_image")

  local ok, err = pcall(usecase, engine, image)
  if not ok then
    vim.notify("Failed to pull image: " .. err, vim.log.levels.ERROR)
    return
  end

  vim.notify("Image pulled successfully: " .. image, vim.log.levels.INFO)
end

--- Remove a specific image by ID
---@param id string
function M.remove(id)
  if not id or id == "" then
    vim.notify("Usage: :Image remove <image-id>", vim.log.levels.WARN)
    return
  end

  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.images.remove_image")

  local ok, err = pcall(usecase, engine, id)
  if not ok then
    vim.notify("Failed to remove image: " .. err, vim.log.levels.ERROR)
    return
  end

  vim.notify("Image removed successfully: " .. id, vim.log.levels.INFO)
end

--- Prune (remove) all dangling images
function M.prune()
  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.images.prune_images")

  local ok, err = pcall(usecase, engine)
  if not ok then
    vim.notify("Failed to prune images: " .. err, vim.log.levels.ERROR)
    return
  end

  vim.notify("All dangling images pruned successfully!", vim.log.levels.INFO)
end

return M
