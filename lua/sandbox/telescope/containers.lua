---@module 'sandbox.telescope.containers'
--- Fuzzy-pick a container and act on it -- an alternative front-end to
--- `:Sandbox container <action> <id>` tab-completion and the container
--- list view's buffer-local keymaps.

return function()
  local notify = require("sandbox.notify")
  local engine = require("sandbox").get_engine()
  if not engine then
    return
  end

  local usecase = require("sandbox.core.usecases.containers.list_containers")
  local containers, err = usecase(engine)
  if not containers then
    notify.error("Failed to list containers: " .. tostring(err), { err = err })
    return
  end

  local container_cmds = require("sandbox.bindings.usrcmds.container_commands")
  ---@param c table
  local function ref(c)
    return c.id or c.name
  end

  require("sandbox.telescope.picker").build({
    title = "Sandbox Containers",
    items = containers,
    entry = function(c)
      local text = string.format(
        "[%s] %s (%s)",
        c.status or "unknown",
        c.name or "<no name>",
        c.id and c.id:sub(1, 12) or "<no id>"
      )
      return { display = text, ordinal = text }
    end,
    keys = {
      { lhs = "<CR>", desc = "inspect", fn = function(c) container_cmds.inspect(ref(c)) end },
      { lhs = "<C-s>", desc = "start", fn = function(c) container_cmds.start(ref(c)) end },
      { lhs = "<C-x>", desc = "stop", fn = function(c) container_cmds.stop(ref(c)) end },
      { lhs = "<C-r>", desc = "restart", fn = function(c) container_cmds.restart(ref(c)) end },
      { lhs = "<C-l>", desc = "logs", fn = function(c) container_cmds.logs(ref(c)) end },
      { lhs = "<C-d>", desc = "remove", fn = function(c) container_cmds.remove(ref(c)) end },
    },
  })
end
