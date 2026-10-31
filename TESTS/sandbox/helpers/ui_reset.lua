--- Test helper: put the editor's windows and buffers back the way they were
--- when the spec file was loaded.
---
--- `:%bwipeout!` is not that: it also wipes the editor's own first buffer, so
--- Neovim creates a fresh `[No Name]` one, and it leaves split and floating
--- windows a view opened standing as long as they show some buffer. The state
--- guard of testing.nvim reports both as a leak of the case.
---
--- The baseline is taken when this module is first required, which a spec
--- does at its top level, before any case runs.

local M = {}

--- @param list integer[]
--- @return table<integer, true>
local function set_of(list)
  local set = {}
  for _, v in ipairs(list) do
    set[v] = true
  end
  return set
end

local base_wins = set_of(vim.api.nvim_list_wins())
local base_bufs = set_of(vim.api.nvim_list_bufs())
local base_tab = vim.api.nvim_get_current_tabpage()
local base_win = vim.api.nvim_get_current_win()
local base_buf = vim.api.nvim_win_get_buf(base_win)

--- Close every window and wipe every buffer the case created, and show the
--- original buffer in the original window again.
function M.restore()
  if vim.api.nvim_tabpage_is_valid(base_tab) then
    pcall(vim.api.nvim_set_current_tabpage, base_tab)
  end
  if vim.api.nvim_win_is_valid(base_win) then
    pcall(vim.api.nvim_set_current_win, base_win)
  end
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if not base_wins[win] and vim.api.nvim_win_is_valid(win) then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end
  if vim.api.nvim_win_is_valid(base_win) and vim.api.nvim_buf_is_valid(base_buf) then
    pcall(vim.api.nvim_win_set_buf, base_win, base_buf)
  end
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if not base_bufs[buf] and vim.api.nvim_buf_is_valid(buf) then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end
end

return M
