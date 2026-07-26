---@module 'sandbox.bindings.usrcmds.registry_commands'
---@brief Registry authentication (`docker/podman login|logout`), needed
--- before push/pull against private registries. Prompts for username via
--- `kit.input` and password via `vim.fn.inputsecret` (masked input, no kit
--- equivalent),
--- then pipes the password to the engine via stdin (--password-stdin)
--- rather than putting it in argv, where it would be visible in the
--- process list or shell history.
---@description
--- Podman (unlike Docker) requires an explicit registry argument for
--- `podman login`/`podman logout` -- it has no implicit Docker Hub default.

local notify = require("sandbox.notify")
local friendly_error = require("sandbox.util.friendly_error")
local M = {}

--- Log in to a registry (prompts for username/password).
---@param registry? string defaults to Docker Hub on Docker; required on Podman
function M.login(registry)
  local engine = require("sandbox").get_engine()
  if not engine then
    return
  end

  require("lib.nvim.ui.kit").input({
    title = "Registry username: ",
    on_submit = function(username)
      if not username or username == "" then
        notify.warn("Login cancelled: no username given")
        return
      end

      -- No kit equivalent for masked input; stays on the native inputsecret.
      local password = vim.fn.inputsecret("Registry password: ")
      if password == "" then
        notify.warn("Login cancelled: no password given")
        return
      end

      local usecase = require("sandbox.core.usecases.registry.login")
      local ok, err = usecase(engine, username, password, registry)
      if not ok then
        notify.error("Registry login failed: " .. friendly_error(err), { registry = registry, err = err })
        return
      end

      notify.info("Logged in to " .. ((registry and registry ~= "") and registry or "Docker Hub"))
    end,
  })
end

--- Log out of a registry.
---@param registry? string defaults to Docker Hub on Docker; required on Podman
function M.logout(registry)
  local engine = require("sandbox").get_engine()
  if not engine then
    return
  end

  local usecase = require("sandbox.core.usecases.registry.logout")
  local ok, err = usecase(engine, registry)
  if not ok then
    notify.error("Registry logout failed: " .. friendly_error(err), { registry = registry, err = err })
    return
  end

  notify.info("Logged out of " .. ((registry and registry ~= "") and registry or "Docker Hub"))
end

return M
