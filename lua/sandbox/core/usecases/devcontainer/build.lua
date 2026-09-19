---@module 'sandbox.core.usecases.devcontainer.build'
--- Build (or pull) a devcontainer's image and start a container from it,
--- mounting the workspace and keeping it alive with `sleep infinity` --
--- matching VS Code's own devcontainer CLI, which overrides the command the
--- same way for images with no long-running default CMD.
---@description
--- Scope: supports `image`, `build.dockerfile`, and `dockerComposeFile` +
--- `service` (delegated to the ComposeEngine's `up`). No devcontainer
--- "features", lifecycle commands (postCreateCommand, ...), or remoteUser
--- support yet.

local run_argv = require("sandbox.util.run_argv")

---@internal
--- devcontainer.json is external input (a checked-out repository's file,
--- not just the user's own typo), and JSONC `null` decodes to `vim.NIL`
--- (truthy userdata) rather than Lua `nil` -- an `or` default does not catch
--- it. Reject anything that is not a genuine string before it is
--- concatenated into a path or shell argument.
--- @param v any
--- @return string|nil
local function safe_string(v)
  if v == vim.NIL or type(v) ~= "string" then
    return nil
  end
  return v
end

--- @param engine table active ContainerEngine
--- @param compose_engine table active ComposeEngine
--- @param engine_name string "docker"|"podman"|"nerdctl" (raw CLI binary name)
--- @param config table parsed devcontainer.json (see util/devcontainer_file.lua)
--- @param workspace_dir string absolute path to the project root
--- @param container_name string name to give the created container
--- @param on_done fun(ok: boolean, result: string|nil)
return function(engine, compose_engine, engine_name, config, workspace_dir, container_name, on_done)
  if type(config) ~= "table" then
    on_done(false, "invalid devcontainer config: not a table")
    return
  end

  if config.dockerComposeFile then
    local file = config.dockerComposeFile
    if type(file) == "table" then
      file = file[1]
    end
    file = safe_string(file)
    if not file then
      on_done(false, "devcontainer.json: dockerComposeFile must be a string (or array of strings)")
      return
    end
    compose_engine.up(workspace_dir .. "/.devcontainer/" .. file, on_done)
    return
  end

  local workspace_folder = safe_string(config.workspaceFolder) or ("/workspaces/" .. vim.fs.basename(workspace_dir))

  local function run(image)
    local ports = {}
    for _, p in ipairs(config.forwardPorts or {}) do
      ports[#ports + 1] = tostring(p) .. ":" .. tostring(p)
    end

    local env = {}
    for k, v in pairs(config.containerEnv or {}) do
      env[#env + 1] = k .. "=" .. tostring(v)
    end

    engine.run_container({
      image = image,
      name = container_name,
      ports = ports,
      volumes = { workspace_dir .. ":" .. workspace_folder },
      env = env,
      command = { "sleep", "infinity" },
    }, on_done)
  end

  local build = type(config.build) == "table" and config.build or nil
  local dockerfile_name = build and safe_string(build.dockerfile) or nil

  if build and build.dockerfile and not dockerfile_name then
    on_done(false, "devcontainer.json: build.dockerfile must be a string")
  elseif dockerfile_name then
    local build_context = safe_string(build.context) or "."
    local context = workspace_dir .. "/.devcontainer/" .. build_context
    local dockerfile = context .. "/" .. dockerfile_name
    run_argv.run_async_captured(
      { engine_name, "build", "-f", dockerfile, "-t", container_name, context },
      function(ok, output)
        if not ok then
          on_done(false, output)
          return
        end
        run(container_name)
      end
    )
  elseif config.image then
    local image = safe_string(config.image)
    if not image then
      on_done(false, "devcontainer.json: image must be a string")
      return
    end
    engine.pull_image(image, function(ok, err)
      if not ok then
        on_done(false, err)
        return
      end
      run(image)
    end)
  else
    on_done(false, "devcontainer.json has none of image, build.dockerfile, or dockerComposeFile")
  end
end
