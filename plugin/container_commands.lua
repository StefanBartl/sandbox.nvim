--[[
  User Commands for Container Operations

  Provides Neovim commands to manage containers
  (list, logs, exec, start, stop, kill, remove, prune, inspect)
  using the active container engine (Docker or Podman).
]]

--- List all containers (running and stopped)
vim.api.nvim_create_user_command("ContainerList", function()
  local core = require("containers")
  local engine = core.get_engine()
  local usecase = require("containers.core.usecases.containers.list_containers")

  local ok, containers = pcall(usecase, engine)
  if not ok or type(containers) ~= "table" then
    local error_view = require("containers.ui.error_view")
    error_view({ "Failed to list containers:", vim.inspect(containers) })
    return
  end

  local view = require("containers.ui.list_view")
  view(containers)
end, {})

--- Show logs of a specific container
--- Usage: :ContainerLogs <container-id>
vim.api.nvim_create_user_command("ContainerLogs", function(opts)
  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.containers.get_container_logs")
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

--- Open a shell session inside a running container
--- Usage: :ContainerExec <container-id> [<shell>]
vim.api.nvim_create_user_command("ContainerExec", function(opts)
  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.containers.exec_in_container")

  local id = opts.fargs[1]
  if not id or id == "" then
    vim.notify("Usage: :ContainerExec <container-id> [<shell>]", vim.log.levels.WARN)
    return
  end

  local shell = opts.fargs[2] or "sh"

  local ok, err = pcall(usecase, engine, id, { shell })
  if not ok then
    vim.notify("Failed to exec in container: " .. err, vim.log.levels.ERROR)
  end
end, { nargs = "*", complete = "file" })

--- Start a stopped container
--- Usage: :ContainerStart <container-id>
vim.api.nvim_create_user_command("ContainerStart", function(opts)
  local engine = require("containers").get_engine()
  if not engine then
    vim.notify("[nvim-containers] No container engine configured.", vim.log.levels.ERROR)
    return
  end

  local usecase = require("containers.core.usecases.containers.start_container")

  local id = opts.args
  if not id or id == "" then
    vim.notify("Usage: :ContainerStart <container-id>", vim.log.levels.WARN)
    return
  end

  local success = usecase(engine, id)
  if not success then
    vim.notify("Failed to start container: " .. id, vim.log.levels.ERROR)
    return
  end

  vim.notify("Container started successfully: " .. id, vim.log.levels.INFO)
end, { nargs = 1 })

--- Stop a running container
--- Usage: :ContainerStop <container-id>
vim.api.nvim_create_user_command("ContainerStop", function(opts)
  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.containers.stop_container")

  local id = opts.args
  if not id or id == "" then
    vim.notify("Usage: :ContainerStop <container-id>", vim.log.levels.WARN)
    return
  end

  local ok, err = pcall(usecase, engine, id)
  if not ok then
    vim.notify("Failed to stop container: " .. err, vim.log.levels.ERROR)
    return
  end

  vim.notify("Container stopped successfully: " .. id, vim.log.levels.INFO)
end, { nargs = 1 })

--- Force kill a container
--- Usage: :ContainerKill <container-id>
vim.api.nvim_create_user_command("ContainerKill", function(opts)
  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.containers.kill_container")

  local id = opts.args
  if not id or id == "" then
    vim.notify("Usage: :ContainerKill <container-id>", vim.log.levels.WARN)
    return
  end

  local ok, err = pcall(usecase, engine, id)
  if not ok then
    vim.notify("Failed to kill container: " .. err, vim.log.levels.ERROR)
    return
  end

  vim.notify("Container killed successfully: " .. id, vim.log.levels.INFO)
end, { nargs = 1 })

--- Remove a container (must be stopped first)
--- Usage: :ContainerRemove <container-id>
vim.api.nvim_create_user_command("ContainerRemove", function(opts)
  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.containers.remove_container")

  local id = opts.args
  if not id or id == "" then
    vim.notify("Usage: :ContainerRemove <container-id>", vim.log.levels.WARN)
    return
  end

  local ok, err = pcall(usecase, engine, id)
  if not ok then
    vim.notify("Failed to remove container: " .. err .. "\nIs it stopped?", vim.log.levels.ERROR)
    return
  end

  vim.notify("Container removed successfully: " .. id, vim.log.levels.INFO)
end, { nargs = 1 })

--- Remove all stopped containers
vim.api.nvim_create_user_command("ContainerPrune", function()
  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.containers.prune_containers")

  local ok, err = pcall(usecase, engine)
  if not ok then
    vim.notify("Failed to prune containers: " .. err, vim.log.levels.ERROR)
    return
  end

  vim.notify("All stopped containers pruned successfully!", vim.log.levels.INFO)
end, {})

--- Inspect detailed information about a container
--- Usage: :ContainerInspect <container-id>
vim.api.nvim_create_user_command("ContainerInspect", function(opts)
  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.containers.inspect_container")
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
