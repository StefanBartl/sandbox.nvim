-- Notify wrapper: uses lib.nvim's notify factory when lib.nvim is installed,
-- falls back to plain vim.notify otherwise (lib.nvim stays an optional dependency).
--
-- warn/error additionally forward to containers.logger for structured
-- diagnostics (raw CLI output, exit codes, ...) via an optional `ctx` table,
-- without showing that context to the user - the logger's own notify sink is
-- off, so this never double-notifies.

local logger = require("containers.logger")

local ok, lib_notify = pcall(require, "lib.nvim.notify")

local base = ok and lib_notify.create("[sandbox.nvim]") or {
  info = function(msg) vim.notify("[sandbox.nvim] " .. msg, vim.log.levels.INFO) end,
  warn = function(msg) vim.notify("[sandbox.nvim] " .. msg, vim.log.levels.WARN) end,
  error = function(msg) vim.notify("[sandbox.nvim] " .. msg, vim.log.levels.ERROR) end,
}

local M = {}

--- @param msg string
function M.info(msg)
  base.info(msg)
end

--- @param msg string
--- @param ctx? table diagnostic context recorded via containers.logger, not shown to the user
function M.warn(msg, ctx)
  base.warn(msg)
  logger.warn(msg, ctx)
end

--- @param msg string
--- @param ctx? table diagnostic context recorded via containers.logger, not shown to the user
function M.error(msg, ctx)
  base.error(msg)
  logger.error(msg, ctx)
end

return M
