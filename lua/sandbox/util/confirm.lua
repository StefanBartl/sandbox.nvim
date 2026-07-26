-- Confirmation gate for destructive actions (remove/prune/kill), skippable
-- via config.confirm_destructive = false.

local kit = require("lib.nvim.ui.kit")

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

  kit.confirm({
    question = prompt,
    on_answer = function(yes)
      if yes then
        on_confirm()
      end
    end,
  })
end

return M
