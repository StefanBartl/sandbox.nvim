---@module 'sandbox.util.confirm'
--- Confirmation gate for destructive actions (remove/prune/kill), skippable
--- via config.confirm_destructive = false.

local M = {}

--- Ask for confirmation before running a destructive action.
--- @param prompt string
--- @param on_confirm fun()
function M.destructive(prompt, on_confirm)
  local config = require("sandbox.config")
  if config.options.confirm_destructive == false then
    on_confirm()
    return
  end

  -- The shared dialog: "No" is the first, focused button; a native question when no float can open.
  require("lib.nvim.ui.dialog").yesno(prompt, "go ahead", function(yes)
    if yes then
      on_confirm()
    end
  end, { kind = "danger" })
end

return M
