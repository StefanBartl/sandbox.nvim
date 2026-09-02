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
-- present under TESTS/, so scope them there rather than loosening checks
-- plugin-wide.
files["TESTS/"] = {
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

-- Eight "unused argument" warnings, one cause: a parameter list that is the
-- contract rather than a variable anybody reads. luacheck exits 1 on a
-- warning, so these have to be scoped off or the whole gate stays red.
--
--   * `lua/sandbox/core/ports/` *is* the engine interface. Every body is
--     `error("... not implemented")`; the names exist so adapters have
--     something to implement against and so LuaLS shows a signature at each
--     call site. Deleting them would delete the documentation.
--   * A stub standing in for a `vim.*` function has to keep the original's
--     arity. LuaLS carries a stub's signature across the whole workspace: a
--     nullary `vim.cmd` made all 24 real `vim.cmd("…")` calls in this repo
--     report "expects 0 arguments". That is what 94193cd fixed, and reverting
--     it to quiet luacheck would trade one tool's complaint for another's.
--
-- Scoped per path rather than set globally, so a genuinely forgotten argument
-- anywhere else is still reported.
files["lua/sandbox/core/ports/"] = { unused_args = false }
files["lua/sandbox/bindings/usrcmds/init.lua"] = { unused_args = false }
files["TESTS/sandbox/adapters/exec_workdir_spec.lua"] = { unused_args = false }
