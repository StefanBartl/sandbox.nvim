-- Minimal init for running the plenary.nvim test suite headlessly:
--   nvim --headless --noplugin -u tests/minimal_init.lua \
--     -c "PlenaryBustedDirectory tests/sandbox { minimal_init = 'tests/minimal_init.lua' }"
--
-- plenary.nvim and lib.nvim are resolved via env vars rather than a
-- hardcoded path, so this works both locally (wherever they're installed
-- for your normal Neovim config) and in CI (checked out into a scratch dir
-- by the workflow). See tests/README.md.

vim.opt.rtp:prepend(vim.fn.getcwd())

local function prepend_env(var)
  local path = os.getenv(var)
  if path and path ~= "" then
    vim.opt.rtp:prepend(path)
  end
end

prepend_env("PLENARY_PATH")
prepend_env("LIB_NVIM_PATH")

vim.cmd("runtime plugin/plenary.vim")
