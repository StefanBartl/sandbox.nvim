---@module 'containers.bindings.usrcmds.container_commands'
---@brief Container operation handlers (list, logs, exec, start, stop, kill,
--- remove, prune, inspect) using the active container engine (Docker/Podman).
---@description
--- Exported as plain functions rather than registering commands directly, so
--- lib.nvim.usercmd.composer's :Container verb (bindings/usrcmds/init.lua)
--- can build typed routes + <Tab> completion around them. Each function's
--- own body is unchanged from before the composer migration; only the
--- registration site moved.

local notify = require("containers.notify")
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
    notify.warn("Usage: :Container logs <container-id>")
    return
  end

  local ok, logs = pcall(usecase, engine, id)
  if not ok then
    notify.error("Failed to get logs: " .. logs)
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
    notify.warn("Usage: :Container exec <container-id> [<shell>]")
    return
  end

  shell = shell or "sh"

  local ok, err = pcall(usecase, engine, id, { shell })
  if not ok then
    notify.error("Failed to exec in container: " .. err)
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
    notify.warn("Usage: :Container exec-once <container-id> [<command>...]")
    return
  end

  if command and vim.tbl_isempty(command) then
    command = nil
  end

  local ok, err = pcall(usecase, engine, id, command)
  if not ok then
    notify.error("Failed to exec in container: " .. err)
  end
end

--- Start a stopped container
---@param id string
function M.start(id)
  local engine = require("containers").get_engine()
  if not engine then
    notify.error("No container engine configured.")
    return
  end

  local usecase = require("containers.core.usecases.containers.start_container")

  if not id or id == "" then
    notify.warn("Usage: :Container start <container-id>")
    return
  end

  local success = usecase(engine, id)
  if not success then
    notify.error("Failed to start container: " .. id)
    return
  end

  notify.info("Container started successfully: " .. id)
end

--- Stop a running container
---@param id string
function M.stop(id)
  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.containers.stop_container")

  if not id or id == "" then
    notify.warn("Usage: :Container stop <container-id>")
    return
  end

  local ok, err = pcall(usecase, engine, id)
  if not ok then
    notify.error("Failed to stop container: " .. err)
    return
  end

  notify.info("Container stopped successfully: " .. id)
end

--- Force kill a container
---@param id string
function M.kill(id)
  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.containers.kill_container")

  if not id or id == "" then
    notify.warn("Usage: :Container kill <container-id>")
    return
  end

  local ok, err = pcall(usecase, engine, id)
  if not ok then
    notify.error("Failed to kill container: " .. err)
    return
  end

  notify.info("Container killed successfully: " .. id)
end

--- Remove a container (must be stopped first)
---@param id string
function M.remove(id)
  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.containers.remove_container")

  if not id or id == "" then
    notify.warn("Usage: :Container remove <container-id>")
    return
  end

  local ok, err = pcall(usecase, engine, id)
  if not ok then
    notify.error("Failed to remove container: " .. err .. "\nIs it stopped?")
    return
  end

  notify.info("Container removed successfully: " .. id)
end

--- Remove all stopped containers
function M.prune()
  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.containers.prune_containers")

  local ok, err = pcall(usecase, engine)
  if not ok then
    notify.error("Failed to prune containers: " .. err)
    return
  end

  notify.info("All stopped containers pruned successfully!")
end

--- Inspect detailed information about a container
---@param id string
function M.inspect(id)
  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.containers.inspect_container")
  local view = require("containers.ui.inspect_view")

  if not id or id == "" then
    notify.warn("Usage: :Container inspect <container-id>")
    return
  end

  local ok, result = pcall(usecase, engine, id)
  if not ok then
    notify.error("Failed to inspect container: " .. result)
    return
  end

  view(result, id)
end

return M
