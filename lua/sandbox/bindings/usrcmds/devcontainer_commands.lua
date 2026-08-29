---@module 'sandbox.bindings.usrcmds.devcontainer_commands'
---@brief Build/attach helpers for a `.devcontainer/devcontainer.json` (or
--- `.devcontainer.json`) detected in cwd or an ancestor directory, similar
--- to VS Code's Dev Containers extension.
---@description
--- Scope: supports `image`, `build.dockerfile`, and `dockerComposeFile` +
--- `service`. No devcontainer "features", lifecycle commands
--- (postCreateCommand, ...), or remoteUser support yet. Single-container devcontainers get a predictable
--- container name (`sandbox-devcontainer-<workspace-dir-basename>`) so
--- `attach` can find what `build` created without extra bookkeeping.

local notify = require("sandbox.notify")
local friendly_error = require("sandbox.util.friendly_error")
local M = {}

---@internal
---@return table|nil config, string|nil path
local function find_and_parse()
  local devcontainer_file = require("sandbox.util.devcontainer_file")
  local path = devcontainer_file.find()
  if not path then
    notify.warn("No .devcontainer/devcontainer.json or .devcontainer.json found in cwd or an ancestor directory")
    return nil, nil
  end

  local config, err = devcontainer_file.parse(path)
  if not config then
    notify.error("Failed to parse " .. path .. ": " .. tostring(err), { path = path, err = err })
    return nil, nil
  end

  return config, path
end

---@internal
---@param workspace_dir string
---@return string
local function container_name_for(workspace_dir)
  return "sandbox-devcontainer-" .. vim.fs.basename(workspace_dir):gsub("[^%w_.-]", "_")
end

--- Build (or pull) the devcontainer's image and start a container from it.
function M.build()
  local config, path = find_and_parse()
  if not config or not path then
    return
  end

  local sandbox = require("sandbox")
  local engine = sandbox.get_engine()
  local compose_engine = sandbox.get_compose_engine()
  if not engine or not compose_engine then
    return
  end

  local devcontainer_file = require("sandbox.util.devcontainer_file")
  local workspace_dir = devcontainer_file.workspace_dir(path)
  local name = container_name_for(workspace_dir)

  notify.info("Building devcontainer...")
  local usecase = require("sandbox.core.usecases.devcontainer.build")
  local engine_name = sandbox.resolve_engine_name() or "docker"
  usecase(engine, compose_engine, engine_name, config, workspace_dir, name, function(ok, result)
    if not ok then
      notify.error("Devcontainer build failed: " .. friendly_error(result), { err = result })
      return
    end
    notify.info("Devcontainer ready. Run :Sandbox devcontainer attach to open a shell.")
  end)
end

--- Exec a shell into the running devcontainer for the project in cwd.
function M.attach()
  local config, path = find_and_parse()
  if not config or not path then
    return
  end

  if config.dockerComposeFile then
    notify.warn(
      "Compose-based devcontainer: use :Sandbox compose ps to find the service container, "
        .. "then :Sandbox container exec <container-id>"
    )
    return
  end

  local devcontainer_file = require("sandbox.util.devcontainer_file")
  local workspace_dir = devcontainer_file.workspace_dir(path)
  local name = container_name_for(workspace_dir)

  require("sandbox.bindings.usrcmds.container_commands").exec(name)
end

return M
