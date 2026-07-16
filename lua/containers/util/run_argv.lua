-- Argv runner: uses lib.nvim's cross.run_argv when lib.nvim is installed,
-- falls back to plain vim.fn.system otherwise (lib.nvim stays an optional
-- dependency, matching containers/notify.lua's convention).

local ok, lib_run_argv = pcall(require, "lib.nvim.cross.run_argv")

local M = {}

if ok then
  M.run_blocking_captured = lib_run_argv.run_blocking_captured
else
  ---@param cmd string[]
  ---@param input? string
  ---@return boolean ok
  ---@return string output
  function M.run_blocking_captured(cmd, input)
    local out = vim.fn.system(cmd, input or "")
    return vim.v.shell_error == 0, out
  end
end

return M
