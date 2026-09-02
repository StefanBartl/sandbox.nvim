---@module 'sandbox.engine_utils'
--- Which container engine to drive, and whether it can actually answer.

local notify = require("sandbox.notify")

local M = {}

--- The engines this plugin can drive, in preference order.
---
--- Declared once rather than written out at each site: the order *is* the
--- policy, and a second copy of it drifts.
---@type Sandbox.Engine[]
M.ENGINES = { "podman", "docker", "nerdctl" }

--- How long a liveness probe may take before the engine counts as silent.
---
--- Measured 2026-09-02 on Windows 11: a `version` call costs ~385 ms whether
--- the daemon answers or refuses, so this timeout is not about the normal
--- case. It is about a daemon that *hangs* rather than refuses, and a hang
--- must never take Neovim with it.
local PROBE_TIMEOUT_MS = 3000

--- Probe results for this session, keyed by engine name.
---@type table<string, boolean>
local responds = {}

--- Check if a command is available on the system.
--- Delegates to lib.nvim.core.has_exec, which memoizes the result per binary
--- name (this module's own version re-checked vim.fn.executable every call).
--- @param cmd string
--- @return boolean
function M.is_executable(cmd)
  return require("lib.nvim.core").has_exec(cmd)
end

--- Whether `name` can actually answer -- not whether its binary exists.
---
--- **The distinction this module was missing.** Being on `PATH` says an
--- engine is *installed*; it says nothing about a daemon being up. On a
--- machine with Podman Desktop installed but its Linux VM stopped, `podman`
--- is on `PATH`, wins the preference order, and every call fails after
--- ~370 ms -- while a perfectly good Docker engine sits beside it, never
--- asked. Found 2026-09-02 by hover.nvim's `scripts/onrequest_probe.lua`,
--- which reported a container preview that was registered, green in every
--- spec, and silent on the machine.
---
--- `version` is the question, plain and without `--format`: all three CLIs
--- accept it, and all three exit non-zero when the *server* half cannot be
--- reached (measured: podman 125, docker 1). A format template would answer
--- the same thing while adding a per-engine difference to get wrong.
---
--- **Memoized for the session**, because the probe is not cheap and no
--- cheaper phrasing exists -- the connect *is* the cost (`version`, `info`
--- and `image ls` measured at 380-640 ms alike). Starting a daemon after
--- Neovim is up is a normal thing to do, so `M.forget()` exists and
--- `:Sandbox engine reset` calls it.
---@param name string
---@return boolean
function M.responds(name)
  if responds[name] ~= nil then
    return responds[name]
  end
  if not M.is_executable(name) then
    responds[name] = false
    return false
  end

  local ok, result = pcall(function()
    return vim.system({ name, "version" }, { text = true }):wait(PROBE_TIMEOUT_MS)
  end)
  responds[name] = ok and type(result) == "table" and result.code == 0
  return responds[name]
end

--- Forget every probe result, so the next question is asked afresh.
---
--- For `:Sandbox engine reset` and for tests. Without it, starting your VM
--- mid-session would leave the plugin on the answer cached before you did.
---@return nil
function M.forget()
  responds = {}
end

--- Every engine whose CLI is on `PATH`, in preference order.
---@return Sandbox.Engine[]
function M.installed()
  local out = {}
  for _, name in ipairs(M.ENGINES) do
    if M.is_executable(name) then
      out[#out + 1] = name
    end
  end
  return out
end

--- The first installed engine, whether or not it answers.
---
--- Cheap on purpose -- `PATH` only, no process started. This is what
--- `config.setup` calls, and `setup` runs at startup: a liveness probe here
--- would cost every Neovim start ~385 ms per installed engine, to answer a
--- question nobody has asked yet.
--- @return Sandbox.Engine
function M.get_engine()
  local installed = M.installed()
  if installed[1] then
    return installed[1]
  end
  notify.error("No supported container engine (podman/docker/nerdctl) found in PATH.")
  return "docker" -- fallback to docker to avoid crash, user will see error
end

--- The first installed engine that actually answers.
---
--- Falls back to `get_engine()` when none of them does, so the error a user
--- eventually sees names a real engine: "docker is not running" is
--- actionable, "no engine" on a machine with three installed is not.
---
--- Costs one probe per installed engine, once per session, and is called
--- only from a site that is about to use the engine anyway.
--- @return Sandbox.Engine
function M.get_live_engine()
  for _, name in ipairs(M.installed()) do
    if M.responds(name) then
      return name
    end
  end
  return M.get_engine()
end

return M
