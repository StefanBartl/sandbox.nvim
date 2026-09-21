-- Minimal init for running the plenary.nvim test suite headlessly:
--   nvim --headless --noplugin -u TESTS/minimal_init.lua \
--     -c "PlenaryBustedDirectory TESTS/sandbox { minimal_init = 'TESTS/minimal_init.lua' }"
--
-- plenary.nvim, lib.nvim and ui.nvim are resolved via env vars rather than
-- a hardcoded path, so this works both locally (wherever they're installed
-- for your normal Neovim config) and in CI (checked out into a scratch dir
-- by the workflow). See TESTS/README.md.

vim.opt.rtp:prepend(vim.fn.getcwd())

local function prepend_env(var)
  local path = os.getenv(var)
  if path and path ~= "" then
    vim.opt.rtp:prepend(path)
  end
end

prepend_env("PLENARY_PATH")
prepend_env("LIB_NVIM_PATH")
-- ui.kit/ui.contextmenu moved out of lib.nvim.ui.kit/lib.nvim.contextmenu
-- in the 2026-09 migration -- ui.nvim is a declared dependency too now.
prepend_env("UI_NVIM_PATH")

vim.cmd("runtime plugin/plenary.vim")

-- Swap and shada stay off for the whole suite, including plenary's child
-- processes that reuse this file: stale swap files fail suites with E326.
vim.o.swapfile = false
vim.o.shadafile = "NONE"
