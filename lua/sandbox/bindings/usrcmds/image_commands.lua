---@module 'sandbox.bindings.usrcmds.image_commands'
---@brief Image operation handlers (list, pull, remove, prune) using the
--- active container engine (Docker/Podman).
---@description
--- Exported as plain functions rather than registering commands directly, so
--- the "image" sub-namespace of the :Sandbox/:Sbx composer verb
--- (bindings/usrcmds/init.lua) can build typed routes + <Tab> completion
--- around them. Each function's own body is unchanged from before the
--- composer migration; only the registration site moved.

local notify = require("sandbox.notify")
local friendly_error = require("sandbox.util.friendly_error")
local confirm = require("sandbox.util.confirm")
local M = {}

--- List all available images
function M.list()
  local config = require("sandbox.config")
  local engine = require("sandbox").get_engine()
  if not engine then
    return
  end

  local usecase = require("sandbox.core.usecases.images.list_images")
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
    view = require("sandbox.ui.image_list_view_docker")
  elseif config.options.engine == "podman" then
    view = require("sandbox.ui.image_list_view_podman")
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
    notify.warn("Usage: :Sandbox image pull <image>")
    return
  end

  local engine = require("sandbox").get_engine()
  if not engine then
    return
  end

  local usecase = require("sandbox.core.usecases.images.pull_image")
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
    notify.warn("Usage: :Sandbox image remove <image-id>")
    return
  end

  local engine = require("sandbox").get_engine()
  if not engine then
    return
  end

  confirm.destructive("Remove image " .. id .. "?", function()
    local usecase = require("sandbox.core.usecases.images.remove_image")
    usecase(engine, id, function(ok, err)
      if ok then
        notify.info("Image removed successfully: " .. id)
      else
        notify.error("Failed to remove image " .. id .. ": " .. friendly_error(err), { id = id, err = err })
      end
    end)
  end)
end

--- Tag a local image with a new repository:tag
---@param source string
---@param target string
function M.tag(source, target)
  if not source or source == "" or not target or target == "" then
    notify.warn("Usage: :Sandbox image tag <source> <target>")
    return
  end

  local engine = require("sandbox").get_engine()
  if not engine then
    return
  end

  local usecase = require("sandbox.core.usecases.images.tag_image")
  local ok, err = usecase(engine, source, target)
  if not ok then
    notify.error("Failed to tag image " .. source .. ": " .. friendly_error(err), { source = source, target = target, err = err })
    return
  end

  notify.info("Tagged: " .. source .. " -> " .. target)
end

--- Save (export) an image to a tarball on disk
---@param image string
---@param path string
function M.save(image, path)
  if not image or image == "" or not path or path == "" then
    notify.warn("Usage: :Sandbox image save <image> <path>")
    return
  end

  local engine = require("sandbox").get_engine()
  if not engine then
    return
  end

  local usecase = require("sandbox.core.usecases.images.save_image")
  local ok, err = usecase(engine, image, path)
  if not ok then
    notify.error("Failed to save image " .. image .. ": " .. friendly_error(err), { image = image, path = path, err = err })
    return
  end

  notify.info("Image saved: " .. image .. " -> " .. path)
end

--- Load (import) an image from a tarball on disk
---@param path string
function M.load(path)
  if not path or path == "" then
    notify.warn("Usage: :Sandbox image load <path>")
    return
  end

  local engine = require("sandbox").get_engine()
  if not engine then
    return
  end

  local usecase = require("sandbox.core.usecases.images.load_image")
  local ok, err = usecase(engine, path)
  if not ok then
    notify.error("Failed to load image from " .. path .. ": " .. friendly_error(err), { path = path, err = err })
    return
  end

  notify.info("Image loaded from: " .. path)
end

--- Show an image's layer history
---@param image string
function M.history(image)
  if not image or image == "" then
    notify.warn("Usage: :Sandbox image history <image>")
    return
  end

  local engine = require("sandbox").get_engine()
  if not engine then
    return
  end

  local usecase = require("sandbox.core.usecases.images.history_image")
  local lines, err = usecase(engine, image)
  if not lines then
    notify.error("Failed to get history for " .. image .. ": " .. friendly_error(err), { image = image, err = err })
    return
  end

  local view = require("sandbox.ui.log_view")
  view(lines, "image-history/" .. image)
end

--- Inspect detailed information about an image
---@param image string
function M.inspect(image)
  if not image or image == "" then
    notify.warn("Usage: :Sandbox image inspect <image>")
    return
  end

  local engine = require("sandbox").get_engine()
  if not engine then
    return
  end

  local usecase = require("sandbox.core.usecases.images.inspect_image")
  local view = require("sandbox.ui.inspect_view")

  local ok, result = pcall(usecase, engine, image)
  if not ok then
    notify.error("Failed to inspect image " .. image .. ": " .. tostring(result), { image = image, err = result })
    return
  end

  view(result, "image-" .. image)
end

--- Prune (remove) all dangling images
function M.prune()
  local engine = require("sandbox").get_engine()
  if not engine then
    return
  end

  confirm.destructive("Prune all dangling images?", function()
    local usecase = require("sandbox.core.usecases.images.prune_images")
    usecase(engine, function(ok, err)
      if ok then
        notify.info("All dangling images pruned successfully!")
      else
        notify.error("Failed to prune images: " .. friendly_error(err), { err = err })
      end
    end)
  end)
end

return M
