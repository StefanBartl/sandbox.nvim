-- Structured diagnostics logger: uses lib.nvim's logger when installed
-- (in-memory ring + JSONL file sink, inspectable via :LibLogger show),
-- falls back to a no-op otherwise (lib.nvim stays an optional dependency,
-- matching containers/notify.lua's convention).
--
-- notify_level is "off": this module never surfaces messages to the user by
-- itself. containers.notify owns all user-facing text; this one only records
-- the full diagnostic context (raw CLI output, exit codes, ...) so it can be
-- inspected later without cluttering the notify popup.

local ok, lib_logger = pcall(require, "lib.nvim.logger")

local M = ok and lib_logger.new({
  name = "nvim-containers",
  notify_level = "off",
}) or {
  trace = function() end,
  debug = function() end,
  info = function() end,
  warn = function() end,
  error = function() end,
}

return M
