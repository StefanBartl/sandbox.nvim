-- Command definitions for lazy-loading

vim.api.nvim_create_user_command("ContainerList", function()
  local core = require("containers")
  local engine = core.get_engine()
  local usecase = require("containers.core.usecases.list_containers")

  local ok, containers = pcall(usecase, engine)

  if not ok or type(containers) ~= "table" then
    local error_view = require("containers.ui.error_view")
    error_view({ "Failed to list containers:", vim.inspect(containers) })
    return
  end

  local view = require("containers.ui.list_view")
  view(containers)

end, {})

vim.api.nvim_create_user_command("ContainerLogs", function(opts)
  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.get_container_logs")
  local view = require("containers.ui.log_view")

  local id = opts.args
  if not id or id == "" then
    vim.notify("Usage: :ContainerLogs <container-id>", vim.log.levels.WARN)
    return
  end

  local ok, logs = pcall(usecase, engine, id)
  if not ok then
    vim.notify("Failed to get logs: " .. logs, vim.log.levels.ERROR)
    return
  end

  view(logs, id)
end, { nargs = 1 })

-- TODO: autocompletion for container-ids ?
vim.api.nvim_create_user_command("ContainerExec", function(opts)
  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.exec_in_container")

  local id = opts.fargs[1]
  if not id or id == "" then
    vim.notify("Usage: :ContainerExec <container-id> [<shell>]", vim.log.levels.WARN)
    return
  end

  local shell = opts.fargs[2] or "sh"

  local ok, err = pcall(usecase, engine, id, { shell })
  if not ok then
    vim.notify("Failed to exec in container: " .. err, vim.log.levels.ERROR)
    return
  end
end, {
  nargs = "*",
  complete = "file",
})

vim.api.nvim_create_user_command("ContainerStart", function(opts)
  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.start_container")

  local id = opts.args
  if not id or id == "" then
    vim.notify("Usage: :ContainerStart <container-id>", vim.logs.levels.WARN)
    return
  end

  local ok, err = pcall(usecase, engine, id)
  if not ok then
    vim.notify("Failed to start container: " .. err, vim.logs.levels.ERROR)
    return
  end
end, { nargs = 1 })

vim.api.nvim_create_user_command("ContainerStop", function(opts)
  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.stop_container")

  local id = opts.args
  if not id or id == "" then
    vim.notify("Usage: :ContainerStop <container-id>", vim.logs.levels.WARN)
    return
  end

  local ok, err = pcall(usecase, engine, id)
  if not ok then
    vim.notify("Failed to stop container: " .. err, vim.logs.level.ERROR)
    return
  end
end, { nargs = 1 })

vim.api.nvim_create_user_command("ContainerKill", function(opts)
  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.kill_container")

  local id = opts.args
  if not id or id == "" then
    vim.notify("Usage: :ContainerKill <container-id>", vim.logs.levels.WARN)
    return
  end

  local ok, err = pcall(usecase, engine, id)
  if not ok then
    vim.notify("Failed to kill container: " .. err, vim.logs.level.ERROR)
    return
  end
end, { nargs = 1 })

vim.api.nvim_create_user_command("ContainerRemove", function(opts)
  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.remove_container")

  local id = opts.args
  if not id or id == "" then
    vim.notify("Usage: :ContainerRemove <container-id>", vim.logs.levels.WARN)
    return
  end

  local ok, err = pcall(usecase, engine, id)
  if not ok then
    vim.notify("Failed to remove container: " .. err, vim.log.levels.ERROR)
    return
  end
end, { nargs = 1 })

vim.api.nvim_create_user_command("ContainerPrune", function()
  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.prune_containers")

  local ok, err = pcall(usecase, engine)
  if not ok then
    vim.notify("Failed to prune containers: " .. err, vim.log.levels.ERROR)
  end
end, {})

vim.api.nvim_create_user_command("ContainerInspect", function(opts)
  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.inspect_container")
  local view = require("containers.ui.inspect_view")

  local id = opts.args
  if not id or id == "" then
    vim.notify("Usage: :ContainerInspect <container-id>", vim.log.levels.WARN)
    return
  end

  local ok, result = pcall(usecase, engine, id)
  if not ok then
    vim.notify("Failed to inspect container: " .. result, vim.log.levels.ERROR)
    return
  end

  view(result, id)
end, { nargs = 1 })

vim.api.nvim_create_user_command("ImageList", function()
  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.list_images")
  local view = require("containers.ui.image_list_view")

  local ok, result = pcall(usecase, engine)
  if not ok then
    vim.notify("Failed to list images: " .. result, vim.log.levels.ERROR)
    return
  end

  view(result)
end, {})

vim.api.nvim_create_user_command("ImagePull", function(opts)
  local image = opts.args
  if not image or image == "" then
    vim.notify("Usage: :ImagePull <image>", vim.log.levels.WARN)
    return
  end

  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.pull_image")

  local ok, err = pcall(usecase, engine, image)
  if not ok then
    vim.notify("Failed to pull image: " .. err, vim.log.levels.ERROR)
  end
end, { nargs = 1 })

vim.api.nvim_create_user_command("ImageRemove", function(opts)
  local id = opts.args
  if not id or id == "" then
    vim.notify("Usage: :ImageRemove <image-id>", vim.log.levels.WARN)
    return
  end

  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.remove_image")

  local ok, err = pcall(usecase, engine, id)
  if not ok then
    vim.notify("Failed to remove image: " .. err, vim.log.levels.ERROR)
  end
end, { nargs = 1 })

vim.api.nvim_create_user_command("ImagePrune", function()
  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.prune_images")

  local ok, err = pcall(usecase, engine)
  if not ok then
    vim.notify("Failed to prune images: " .. err, vim.log.levels.ERROR)
  end
end, {})
