---@module 'sandbox.telescope.wsl'
--- Fuzzy-pick a registered WSL distro and act on it.

return function()
  local notify = require("sandbox.notify")
  local wsl_cmds = require("sandbox.bindings.usrcmds.wsl_commands")
  if not wsl_cmds.available() then
    notify.warn("WSL not found in PATH")
    return
  end

  local wsl_engine = require("sandbox.adapters.wsl.engine")
  local usecase = require("sandbox.core.usecases.wsl.list_distros")
  local distros, err = usecase(wsl_engine)
  if not distros then
    notify.error("Failed to list WSL distros: " .. tostring(err), { err = err })
    return
  end

  require("sandbox.telescope.picker").build({
    title = "Sandbox WSL Distros",
    items = distros,
    entry = function(d)
      local text = string.format("%s [%s]%s", d.name, d.state, d.default and " (default)" or "")
      return { display = text, ordinal = text }
    end,
    keys = {
      {
        lhs = "<CR>",
        desc = "exec",
        fn = function(d)
          wsl_cmds.exec(d.name)
        end,
      },
      {
        lhs = "<C-s>",
        desc = "start",
        fn = function(d)
          wsl_cmds.start(d.name)
        end,
      },
      {
        lhs = "<C-x>",
        desc = "stop",
        fn = function(d)
          wsl_cmds.stop(d.name)
        end,
      },
      {
        lhs = "<C-d>",
        desc = "set default",
        fn = function(d)
          wsl_cmds.set_default(d.name)
        end,
      },
    },
  })
end
