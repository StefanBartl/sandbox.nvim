---@module 'sandbox.ui.highlights'
--- Highlight groups for container state, linked to built-ins so they follow
--- the user's colorscheme instead of hardcoding colors.
local M = {}

local defined = false

--- Define the groups once per session (idempotent).
function M.ensure_defined()
  if defined then
    return
  end
  defined = true
  vim.api.nvim_set_hl(0, "SandboxStatusRunning", { link = "DiagnosticOk", default = true })
  vim.api.nvim_set_hl(0, "SandboxStatusStopped", { link = "DiagnosticError", default = true })
  vim.api.nvim_set_hl(0, "SandboxStatusPaused", { link = "DiagnosticWarn", default = true })
  vim.api.nvim_set_hl(0, "SandboxStatusOther", { link = "Comment", default = true })
end

--- Classify a raw engine status string (e.g. "Up 3 minutes", "Exited (0) ...",
--- "Paused") into one of the groups defined above.
---@param status string|nil
---@return string
function M.group_for_status(status)
  status = (status or ""):lower()
  if status:find("^up") or status:find("running") then
    return "SandboxStatusRunning"
  elseif status:find("paused") then
    return "SandboxStatusPaused"
  elseif status:find("exited") or status:find("dead") or status:find("stopped") then
    return "SandboxStatusStopped"
  end
  return "SandboxStatusOther"
end

return M
