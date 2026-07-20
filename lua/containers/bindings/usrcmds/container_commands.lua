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
local friendly_error = require("containers.util.friendly_error")
local M = {}

--- List all containers (running and stopped)
function M.list()
  local engine = require("containers").get_engine()
  if not engine then
    return
  end

  local usecase = require("containers.core.usecases.containers.list_containers")
  local containers, err = usecase(engine)

  if not containers then
    local error_view = require("containers.ui.error_view")
    error_view({ "Failed to list containers:", err or "unknown error" })
    return
  end

  if err then
    notify.warn("Some containers could not be parsed: " .. friendly_error(err), { err = err })
  end

  local view = require("containers.ui.list_view")
  view(containers)
end

--- Show logs of a specific container
---@param id string
function M.logs(id)
  local engine = require("containers").get_engine()
  if not engine then
    return
  end

  if not id or id == "" then
    notify.warn("Usage: :Container logs <container-id>")
    return
  end

  local usecase = require("containers.core.usecases.containers.get_container_logs")
  local logs, err = usecase(engine, id)
  if not logs then
    notify.error("Failed to get logs for " .. id .. ": " .. friendly_error(err), { id = id, err = err })
    return
  end

  local view = require("containers.ui.log_view")
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
    notify.error("Failed to exec in container " .. id .. ": " .. tostring(err), { id = id, err = err })
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
    notify.error("Failed to exec in container " .. id .. ": " .. tostring(err), { id = id, err = err })
  end
end

--- Start a stopped container
---@param id string
function M.start(id)
  local engine = require("containers").get_engine()
  if not engine then
    return
  end

  if not id or id == "" then
    notify.warn("Usage: :Container start <container-id>")
    return
  end

  local usecase = require("containers.core.usecases.containers.start_container")
  local ok, err = usecase(engine, id)
  if not ok then
    notify.error("Failed to start container " .. id .. ": " .. friendly_error(err), { id = id, err = err })
    return
  end

  notify.info("Container started successfully: " .. id)
end

--- Stop a running container
---@param id string
function M.stop(id)
  local engine = require("containers").get_engine()
  if not engine then
    return
  end

  if not id or id == "" then
    notify.warn("Usage: :Container stop <container-id>")
    return
  end

  local usecase = require("containers.core.usecases.containers.stop_container")
  usecase(engine, id, function(ok, err)
    if ok then
      notify.info("Container stopped successfully: " .. id)
    else
      notify.error("Failed to stop container " .. id .. ": " .. friendly_error(err), { id = id, err = err })
    end
  end)
end

--- Force kill a container
---@param id string
function M.kill(id)
  local engine = require("containers").get_engine()
  if not engine then
    return
  end

  if not id or id == "" then
    notify.warn("Usage: :Container kill <container-id>")
    return
  end

  local usecase = require("containers.core.usecases.containers.kill_container")
  usecase(engine, id, function(ok, err)
    if ok then
      notify.info("Container killed successfully: " .. id)
    else
      notify.error("Failed to kill container " .. id .. ": " .. friendly_error(err), { id = id, err = err })
    end
  end)
end

--- Remove a container (must be stopped first)
---@param id string
function M.remove(id)
  local engine = require("containers").get_engine()
  if not engine then
    return
  end

  if not id or id == "" then
    notify.warn("Usage: :Container remove <container-id>")
    return
  end

  local usecase = require("containers.core.usecases.containers.remove_container")
  usecase(engine, id, function(ok, err)
    if ok then
      notify.info("Container removed successfully: " .. id)
    else
      notify.error(
        "Failed to remove container " .. id .. ": " .. friendly_error(err) .. "\nIs it stopped?",
        { id = id, err = err }
      )
    end
  end)
end

--- Remove all stopped containers
function M.prune()
  local engine = require("containers").get_engine()
  if not engine then
    return
  end

  local usecase = require("containers.core.usecases.containers.prune_containers")
  usecase(engine, function(ok, err)
    if ok then
      notify.info("All stopped containers pruned successfully!")
    else
      notify.error("Failed to prune containers: " .. friendly_error(err), { err = err })
    end
  end)
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
    notify.error("Failed to inspect container " .. id .. ": " .. tostring(result), { id = id, err = result })
    return
  end

  view(result, id)
end

return M
