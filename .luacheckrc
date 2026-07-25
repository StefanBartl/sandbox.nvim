std = "lua51"

globals = {
  "vim",
}

-- table.unpack is Lua 5.2+ (not part of std lua51), but Neovim's Lua
-- runtime provides it as a compat shim and the codebase uses it.
read_globals = {
  table = { fields = { "unpack" } },
}

-- plenary.nvim's busted-style harness (describe/it/...) and luassert's
-- runtime-extended `assert` (assert.is_true, assert.are.same, ...) are only
-- present under tests/, so scope them there rather than loosening checks
-- plugin-wide.
files["tests/"] = {
  globals = {
    "vim",
    "assert",
    "describe",
    "it",
    "before_each",
    "after_each",
    "pending",
  },
}
