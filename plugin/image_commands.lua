--[[
  User Commands for Image Operations

  Provides Neovim commands to manage container images
  (list, pull, remove, prune) using the active container engine (Docker or Podman).
]]

--- List all available images
vim.api.nvim_create_user_command("ImageList", function()
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
end, {})

--- Pull a specific image by name
--- Usage: :ImagePull <image-name>
vim.api.nvim_create_user_command("ImagePull", function(opts)
  local image = opts.args
  if not image or image == "" then
    vim.notify("Usage: :ImagePull <image>", vim.log.levels.WARN)
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
end, { nargs = 1 })

--- Remove a specific image by ID
--- Usage: :ImageRemove <image-id>
vim.api.nvim_create_user_command("ImageRemove", function(opts)
  local id = opts.args
  if not id or id == "" then
    vim.notify("Usage: :ImageRemove <image-id>", vim.log.levels.WARN)
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
end, { nargs = 1 })

--- Prune (remove) all dangling images
vim.api.nvim_create_user_command("ImagePrune", function()
  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.images.prune_images")

  local ok, err = pcall(usecase, engine)
  if not ok then
    vim.notify("Failed to prune images: " .. err, vim.log.levels.ERROR)
    return
  end

  vim.notify("All dangling images pruned successfully!", vim.log.levels.INFO)
end, {})
