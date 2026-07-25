std = "lua51"

globals = {
  "vim",
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
