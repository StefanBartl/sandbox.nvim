-- Confirmation gate for destructive actions (remove/prune/kill), skippable
-- via config.confirm_destructive = false.

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

  vim.ui.select({ "Yes", "No" }, { prompt = prompt }, function(choice)
    if choice == "Yes" then
      on_confirm()
    end
  end)
end

return M
