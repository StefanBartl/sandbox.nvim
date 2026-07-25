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

--- Run `cmd` without blocking the UI thread, invoking `on_done(ok, output)`
--- once it exits. For long-running ops (`pull`, `prune`, `build`) where
--- `run_blocking_captured` would freeze Neovim until the process finishes.
--- @param cmd string[]
--- @param on_done fun(ok: boolean, output: string)
--- @return table handle with a `:stop()` method
function M.run_async_captured(cmd, on_done)
  local chunks = {}

  local function collect(_, data)
    if data and data ~= "" then
      chunks[#chunks + 1] = data
    end
  end

  local job = vim.system(cmd, { stdout = collect, stderr = collect }, function(obj)
    vim.schedule(function()
      on_done(obj.code == 0, table.concat(chunks))
    end)
  end)

  return {
    stop = function()
      job:kill("sigterm")
    end,
  }
end

return M
