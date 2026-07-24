---@module 'sandbox.bindings.usrcmds.compose_commands'
---@brief Compose orchestration handlers (up/down/restart/ps/logs) scoped to
--- a docker-compose.yml/compose.yml/podman-compose.yml auto-detected in the
--- cwd or an ancestor directory (see util/compose_file.lua).
---@description
--- Unlike container/image/volume/network commands these take no id/name
--- argument -- there is exactly one compose project per detected file, and
--- the file is resolved fresh on every call so switching cwd/buffer picks up
--- a different project automatically.

local notify = require("sandbox.notify")
local friendly_error = require("sandbox.util.friendly_error")
local compose_file = require("sandbox.util.compose_file")
local M = {}

---@return string|nil
local function require_file()
  local file = compose_file.find()
  if not file then
    notify.warn("No docker-compose.yml/compose.yml/podman-compose.yml found in cwd or an ancestor directory")
    return nil
  end
  return file
end

--- Bring the detected compose project up, detached
function M.up()
  local file = require_file()
  if not file then
    return
  end
  local engine = require("sandbox").get_compose_engine()
  if not engine then
    return
  end

  local usecase = require("sandbox.core.usecases.compose.up")
  usecase(engine, file, function(ok, err)
    if ok then
      notify.info("Compose project started: " .. file)
    else
      notify.error("Failed to bring compose project up: " .. friendly_error(err), { file = file, err = err })
    end
  end)
end

--- Stop and remove the detected compose project
function M.down()
  local file = require_file()
  if not file then
    return
  end
  local engine = require("sandbox").get_compose_engine()
  if not engine then
    return
  end

  local usecase = require("sandbox.core.usecases.compose.down")
  usecase(engine, file, function(ok, err)
    if ok then
      notify.info("Compose project stopped: " .. file)
    else
      notify.error("Failed to bring compose project down: " .. friendly_error(err), { file = file, err = err })
    end
  end)
end

--- Restart the detected compose project
function M.restart()
  local file = require_file()
  if not file then
    return
  end
  local engine = require("sandbox").get_compose_engine()
  if not engine then
    return
  end

  local usecase = require("sandbox.core.usecases.compose.restart")
  usecase(engine, file, function(ok, err)
    if ok then
      notify.info("Compose project restarted: " .. file)
    else
      notify.error("Failed to restart compose project: " .. friendly_error(err), { file = file, err = err })
    end
  end)
end

--- List services in the detected compose project
function M.ps()
  local file = require_file()
  if not file then
    return
  end
  local engine = require("sandbox").get_compose_engine()
  if not engine then
    return
  end

  local usecase = require("sandbox.core.usecases.compose.ps")
  local lines, err = usecase(engine, file)
  if not lines then
    notify.error("Failed to list compose services: " .. friendly_error(err), { file = file, err = err })
    return
  end

  local view = require("sandbox.ui.log_view")
  view(lines, "compose-ps")
end

--- Show logs for the detected compose project
function M.logs()
  local file = require_file()
  if not file then
    return
  end
  local engine = require("sandbox").get_compose_engine()
  if not engine then
    return
  end

  local usecase = require("sandbox.core.usecases.compose.logs")
  local lines, err = usecase(engine, file)
  if not lines then
    notify.error("Failed to get compose logs: " .. friendly_error(err), { file = file, err = err })
    return
  end

  local view = require("sandbox.ui.log_view")
  view(lines, "compose-logs")
end

return M
