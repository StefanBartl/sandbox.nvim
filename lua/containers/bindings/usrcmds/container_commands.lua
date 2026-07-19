---@module 'containers.bindings.usrcmds.container_commands'
---@brief Container operation handlers (list, logs, exec, start, stop, kill,
--- remove, prune, inspect) using the active container engine (Docker/Podman).
---@description
--- Exported as plain functions rather than registering commands directly, so
--- lib.nvim.usercmd.composer's :Container verb (bindings/usrcmds/init.lua)
--- can build typed routes + <Tab> completion around them. Each function's
--- own body is unchanged from before the composer migration; only the
--- registration site moved.

local M = {}

--- List all containers (running and stopped)
function M.list()
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
end

--- Show logs of a specific container
---@param id string
function M.logs(id)
  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.containers.get_container_logs")
  local view = require("containers.ui.log_view")

  if not id or id == "" then
    vim.notify("Usage: :Container logs <container-id>", vim.log.levels.WARN)
    return
  end

  local ok, logs = pcall(usecase, engine, id)
  if not ok then
    vim.notify("Failed to get logs: " .. logs, vim.log.levels.ERROR)
    return
  end

  view(logs, id)
end

--- Open a shell session inside a running container
---@param id string
---@param shell? string
function M.exec(id, shell)
  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.containers.exec_in_container")

  if not id or id == "" then
    vim.notify("Usage: :Container exec <container-id> [<shell>]", vim.log.levels.WARN)
    return
  end

  shell = shell or "sh"

  local ok, err = pcall(usecase, engine, id, { shell })
  if not ok then
    vim.notify("Failed to exec in container: " .. err, vim.log.levels.ERROR)
  end
end

--- Execute a one-off command inside a container and show the output.
--- Unlike M.exec, this does not open an interactive shell session.
---@param id string
---@param command string[]|nil
function M.exec_once(id, command)
  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.containers.exec_in_container")

  if not id or id == "" then
    vim.notify("Usage: :Container exec-once <container-id> [<command>...]", vim.log.levels.WARN)
    return
  end

  if command and vim.tbl_isempty(command) then
    command = nil
  end

  local ok, err = pcall(usecase, engine, id, command)
  if not ok then
    vim.notify("Failed to exec in container: " .. err, vim.log.levels.ERROR)
  end
end

--- Start a stopped container
---@param id string
function M.start(id)
  local engine = require("containers").get_engine()
  if not engine then
    vim.notify("[nvim-containers] No container engine configured.", vim.log.levels.ERROR)
    return
  end

  local usecase = require("containers.core.usecases.containers.start_container")

  if not id or id == "" then
    vim.notify("Usage: :Container start <container-id>", vim.log.levels.WARN)
    return
  end

  local success = usecase(engine, id)
  if not success then
    vim.notify("Failed to start container: " .. id, vim.log.levels.ERROR)
    return
  end

  vim.notify("Container started successfully: " .. id, vim.log.levels.INFO)
end

--- Stop a running container
---@param id string
function M.stop(id)
  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.containers.stop_container")

  if not id or id == "" then
    vim.notify("Usage: :Container stop <container-id>", vim.log.levels.WARN)
    return
  end

  local ok, err = pcall(usecase, engine, id)
  if not ok then
    vim.notify("Failed to stop container: " .. err, vim.log.levels.ERROR)
    return
  end

  vim.notify("Container stopped successfully: " .. id, vim.log.levels.INFO)
end

--- Force kill a container
---@param id string
function M.kill(id)
  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.containers.kill_container")

  if not id or id == "" then
    vim.notify("Usage: :Container kill <container-id>", vim.log.levels.WARN)
    return
  end

  local ok, err = pcall(usecase, engine, id)
  if not ok then
    vim.notify("Failed to kill container: " .. err, vim.log.levels.ERROR)
    return
  end

  vim.notify("Container killed successfully: " .. id, vim.log.levels.INFO)
end

--- Remove a container (must be stopped first)
---@param id string
function M.remove(id)
  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.containers.remove_container")

  if not id or id == "" then
    vim.notify("Usage: :Container remove <container-id>", vim.log.levels.WARN)
    return
  end

  local ok, err = pcall(usecase, engine, id)
  if not ok then
    vim.notify("Failed to remove container: " .. err .. "\nIs it stopped?", vim.log.levels.ERROR)
    return
  end

  vim.notify("Container removed successfully: " .. id, vim.log.levels.INFO)
end

--- Remove all stopped containers
function M.prune()
  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.containers.prune_containers")

  local ok, err = pcall(usecase, engine)
  if not ok then
    vim.notify("Failed to prune containers: " .. err, vim.log.levels.ERROR)
    return
  end

  vim.notify("All stopped containers pruned successfully!", vim.log.levels.INFO)
end

--- Inspect detailed information about a container
---@param id string
function M.inspect(id)
  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.containers.inspect_container")
  local view = require("containers.ui.inspect_view")

  if not id or id == "" then
    vim.notify("Usage: :Container inspect <container-id>", vim.log.levels.WARN)
    return
  end

  local ok, result = pcall(usecase, engine, id)
  if not ok then
    vim.notify("Failed to inspect container: " .. result, vim.log.levels.ERROR)
    return
  end

  view(result, id)
end

return M
