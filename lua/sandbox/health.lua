---@module 'sandbox.health'
--- Healthcheck for sandbox.nvim

local config = require("sandbox.config")
local health = vim.health
local engine_utils = require("sandbox.engine_utils")

local M = {}

--- Perform plugin health check
function M.check()
  health.start("sandbox.nvim healthcheck")

  -- The *resolved* engine, not the configured default: a session override or
  -- a project's `.sandboxrc` is what commands actually use, and a healthcheck
  -- reporting the other one answers a question nobody asked.
  local engine = require("sandbox").resolve_engine_name()

  -- Check if engine is set
  if not engine then
    health.error("No container engine configured (nil)")
    return
  end

  -- Validate engine value
  if engine ~= "podman" and engine ~= "docker" and engine ~= "nerdctl" then
    health.error("Invalid container engine configured: " .. tostring(engine))
    return
  else
    health.ok("Container engine in use: " .. engine)
  end

  -- Check if engine CLI exists
  if engine_utils.is_executable(engine) then
    health.ok(engine .. " CLI executable found")
  else
    health.error(engine .. " CLI executable not found in PATH")
  end

  -- Being on PATH is not being able to answer, and the difference is the
  -- whole reason this section exists. A stopped Podman VM leaves `podman` on
  -- PATH and every call failing after ~370 ms; from the outside that looks
  -- exactly like a plugin that does nothing.
  if engine_utils.responds(engine) then
    health.ok(engine .. " answers")
  else
    local alternatives = {}
    for _, name in ipairs(engine_utils.installed()) do
      if name ~= engine and engine_utils.responds(name) then
        alternatives[#alternatives + 1] = name
      end
    end
    if #alternatives > 0 then
      health.error(engine .. " does not answer -- every command will fail", {
        "These do answer: " .. table.concat(alternatives, ", ") .. ".",
        "`:Sandbox engine set "
          .. alternatives[1]
          .. "` for this session, or "
          .. '`engine = "'
          .. alternatives[1]
          .. '"` in setup to make it permanent.',
      })
    else
      health.error(engine .. " does not answer -- is its daemon running?", {
        "Start it, then `:Sandbox engine reset` so the answer is asked again.",
      })
    end
  end

  -- WSL availability check (informational, not an error if absent)
  if engine_utils.is_executable("wsl") then
    health.ok("WSL executable found – WslList/WslStart/WslStop/WslExec commands available")
  else
    health.info("WSL not found in PATH – WSL commands not registered (expected on Linux/macOS)")
  end

  -- The hover integration can be absent for three unrelated reasons, and none
  -- of them says anything at the point of use: the float simply never opens.
  -- Naming which one is the whole value of reporting it here.
  if config.options.hover == false then
    health.info("Hover integration disabled (opts.hover = false)")
  elseif not pcall(require, "hover.registry") then
    health.info("hover.nvim not installed – image previews unavailable (optional)")
  elseif require("sandbox.hover").registered() then
    health.ok("hover.nvim image preview registered – ask for it with :Hover show")
  else
    health.warn(
      "hover.nvim is installed but does not support request-only contributions, "
        .. "so the image preview was not registered: an engine call costs "
        .. "300-750 ms and would stutter the automatic trigger. Update hover.nvim."
    )
  end

  require("lib.nvim.bindings.usercmd.composer").checkhealth("Sandbox")
end

return M
