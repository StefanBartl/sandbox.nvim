-- .testing.lua -- configuration of testing.nvim for this project.
-- Written by `testing migrate`; edit freely (it is never overwritten). Every key is optional; the
-- keys are documented in testing.nvim's docs/CONFIG.md. Loading this file executes it (same trust
-- as running the specs).
return {
  -- Lua module root of the project.
  plugin = "sandbox",
  -- Where the specs live (relative to this directory).
  roots = { "TESTS/sandbox" },
  -- How the spec files are run: "auto" = sniffed per file, "h" = on the project's own TESTS/harness.lua,
  -- "script" = a self-running script in its own process.
  dialect = "auto",
  -- Dependencies (directory names) put on the runtimepath: $<NAME>_DIR, .deps/<name>, ../<name>,
  -- stdpath('data')/lazy/<name>.
  deps = { "lib.nvim", "ui.nvim" },
  -- "none" = all specs in one nvim, "file" = one nvim per spec file
  -- (nothing leaks from one file into the next).
  isolated = "file",
  -- "c" = child started from a -c command (v:vim_did_enter is 0, <cword> works),
  -- "l" = `nvim -l`.
  host = "c",
  -- Guards (safety nets, see testing.nvim docs/GUARDS.md). The suite is clean for fs, scheduled errors,
  -- prompts and deprecations, so those fail the run; process_net is switched on and only lets the
  -- allowlisted spawns below through.
  guards = {
    fs = "error",
    scheduled_error = "error",
    prompt = "error",
    deprecation = "error",
    process_net = "error",
    -- Real leaks between cases remain (about 266 warnings): the usrcmds/container and list/log/inspect
    -- view specs leave scratch buffers, windows and floating windows open, and the lib.nvim logger and
    -- kit surface/toast autocmd groups, the :LibLogger and :KitPreview commands and timers behind.
    -- Stays "warn" until those specs close what they open.
    state = "warn",
  },
  guard_allow = {
    -- run_argv_spec starts real trivial processes (cmd on Windows; echo, printf and sleep elsewhere) and a deliberately
    -- non-existent binary to test the failed-spawn path; both are the subject of the spec.
    spawn = { "cmd", "echo", "printf", "sleep", "sandbox-nvim-definitely-not-a-real-binary" },
  },
}
