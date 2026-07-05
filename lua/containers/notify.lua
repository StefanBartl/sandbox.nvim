-- Notify wrapper: uses lib.nvim's notify factory when lib.nvim is installed,
-- falls back to plain vim.notify otherwise (lib.nvim stays an optional dependency).

local ok, lib_notify = pcall(require, "lib.nvim.notify")

local M = ok and lib_notify.create("[nvim-containers]") or {
  notify = function(msg, level, opts) vim.notify("[nvim-containers] " .. msg, level, opts) end,
  info = function(msg, opts) vim.notify("[nvim-containers] " .. msg, vim.log.levels.INFO, opts) end,
  warn = function(msg, opts) vim.notify("[nvim-containers] " .. msg, vim.log.levels.WARN, opts) end,
  error = function(msg, opts) vim.notify("[nvim-containers] " .. msg, vim.log.levels.ERROR, opts) end,
}

return M
