# sandbox.nvim tests

A [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) busted-style
suite. Adapters are tested against a faked `sandbox.util.run_argv`
(`TESTS/sandbox/helpers/fake_run_argv.lua`) instead of a real
docker/podman/nerdctl/wsl binary — no engine needs to be installed to run
these.

## Running locally

Point `PLENARY_PATH`, `LIB_NVIM_PATH` and `UI_NVIM_PATH` at wherever those
three plugins live in your own setup (e.g. your plugin manager's install
dir), then:

```bash
PLENARY_PATH=/path/to/plenary.nvim \
LIB_NVIM_PATH=/path/to/lib.nvim \
UI_NVIM_PATH=/path/to/ui.nvim \
nvim --headless --noplugin -u TESTS/minimal_init.lua \
  -c "PlenaryBustedDirectory TESTS/sandbox { minimal_init = 'TESTS/minimal_init.lua' }"
```

A single file:

```bash
PLENARY_PATH=... LIB_NVIM_PATH=... UI_NVIM_PATH=... \
nvim --headless --noplugin -u TESTS/minimal_init.lua \
  -c "lua require('plenary.busted').run('TESTS/sandbox/util/run_argv_spec.lua')"
```

Or a subdirectory:

```bash
PLENARY_PATH=... LIB_NVIM_PATH=... UI_NVIM_PATH=... \
nvim --headless --noplugin -u TESTS/minimal_init.lua \
  -c "PlenaryBustedDirectory TESTS/sandbox/util { minimal_init = 'TESTS/minimal_init.lua' }"
```

**Not `PlenaryBustedFile`**, even though it looks like the obvious counterpart
to `PlenaryBustedDirectory`. It spawns a child Neovim to run the file — like
the directory command does — but it takes no options, so it has no
`minimal_init` to pass on. The child therefore starts *without* `-u` and loads
your full personal config instead of `TESTS/minimal_init.lua`, which means
`PLENARY_PATH`/`LIB_NVIM_PATH`/`UI_NVIM_PATH` are never prepended and the spec
runs against whatever versions your plugin manager happens to have installed.
The `-u TESTS/minimal_init.lua` on the outer command only configures the
parent, which does nothing but spawn.

That fails quietly and asymmetrically: a spec can go red under
`PlenaryBustedFile` and green in CI (or the reverse) without anything being
wrong with the spec. `TESTS/sandbox/util/run_argv_spec.lua`'s progress-indicator
case does exactly that. The two forms above run the spec against the same
environment CI uses.

The lint gates CI runs are `luacheck lua TESTS` and `stylua --check .` —
`TESTS/` is part of both.

## Writing a new spec

- One spec file per adapter/module, mirroring `lua/sandbox/...`'s path
  under `TESTS/sandbox/...`.
- `require("TESTS.sandbox.helpers.fake_run_argv")` to fake the shell-out
  layer; see `TESTS/sandbox/adapters/docker/containers_spec.lua` for the
  pattern (`install()` a fake, `reload()` the module under test so it
  re-requires `run_argv` and picks up the fake, assert on `state.calls`).
  `reload_prefix("sandbox.adapters.docker.")` does the same for a whole
  subtree, which is what the aggregators need: `engine.lua` copies its
  sub-aggregators' functions into a table at load time, so re-requiring only
  the top file would hand back functions that closed over the *real* runner.
- Each spec file runs in its own `nvim --headless` subprocess (plenary
  spawns one per file), so faked modules never leak between files — only
  between `it()` blocks *within* the same file, which is why `reload()`
  exists.
- Build fixtures under `vim.fn.tempname()` and delete them afterwards.
  Nothing in this suite writes inside the repository. `compose_find_spec`
  moves the cwd (there is no way to ask `compose_file.find` about another
  directory) and restores it either way.

## No engine, no process, no network

Nothing in this suite starts a container runtime, and no spec runs a payload.
Every spawn is cut at a seam that is replaced **before** the module under test
is required — the adapters bind their dependencies to upvalues at load time, so
a fake installed afterwards would never be seen. What is asserted is the argv
that *would* have been spawned.

| Spawn mechanism | Used by | Seam |
|---|---|---|
| `sandbox.util.run_argv` | most adapters, `devcontainer.build` | `helpers/fake_run_argv.lua` via `package.preload` |
| `vim.fn.jobstart` | the fire-and-forget mutations (`kill`, `rm`, `stop`, `run`, `rmi`, `network rm`, `volume rm`) | `vim.fn.jobstart` replaced per spec |
| `vim.fn.jobstart({ term = true })` / `vim.fn.termopen` | `exec_in_container`, `exec_in_distro`, `container_commands_buffer` | both replaced (whichever the running Neovim takes) |
| `vim.system` | `containers/follow_logs`, `engine_utils.responds`' liveness probe | `vim.system` replaced per spec |
| `ui.kit` prompts | `container run`, `registry login`, the `f` filter, rename | `package.loaded["ui.kit"]` doubles |
| `vim.health` | `health.check` | replaced *before* `sandbox.health` is required |
| `telescope.pickers`/`finders`/`config`/`actions`/`actions.state` | `telescope/picker.lua`'s `build()` | `package.loaded[...]` doubles, same idea as the `ui.kit` row above |

The one exception, stated rather than hidden: `TESTS/sandbox/util/run_argv_spec.lua`
runs the real runner against a trivial command (that runner is the module under
test), and `engine_utils_spec` fakes only the probe, never `vim.fn.executable`'s
own lookup.

## Coverage

### Covered

**The spawn boundary** — `adapters/argv_matrix_spec.lua` drives every method of
every engine aggregator (docker, podman, nerdctl) plus the WSL engine and
asserts the exact argv, including paths with spaces, a registry host with a
port, and a stdin-only password. This is where the places podman is *not* a
rename of docker are pinned: `stop --timeout 1` vs `--time=1`, and
`ps`/`images --format json` vs the Go template. `adapters/callbacks_spec.lua`
covers what comes back afterwards (exit 0 / exit N / stderr / no stderr / no
callback at all), and `adapters/parsing_spec.lua` covers every list and inspect
parser, both output shapes, the partially-undecodable case, and the WSL
`--list --verbose` parser.

**The use-case layer** — `core/usecases_contract_spec.lua` pins all 55
one-line delegations from one table (method name, argument order, both return
values), checks the table is exhaustive against the files on disk, and checks
every method it names exists on the engine that is supposed to provide it.
`core/usecases/devcontainer_build_spec.lua` covers the one use case with logic:
the three strategies, the `build` argv, and the assembled `run_container`
options. `core/ports_spec.lua` pins the interface itself — every port method is
implemented by every adapter claiming that port, in both directions, and the
stubs raise with the method's name in the message (`statusline` and
`container_commands.inspect` both `pcall` because of that).

**Config, state, the public API** — `config_spec.lua` (defaults, deep merge,
cumulative `setup`, the `engine_named` flag, no write-through to `DEFAULTS`),
`init_spec.lua` + `init_api_spec.lua` (the precedence chain, the fall-through to
the liveness probe, both getters, the hover registration gate),
`engine_utils_spec.lua` (installed vs. answers, the memoization — including that
a *no* is remembered for the session, which is what `:Sandbox engine reset` is
for — the probe timeout, and a probe that raises), `util/friendly_error_spec.lua`
(every known pattern, the first-line fallback, the cap and where it says the
rest is), `statusline_spec.lua` (cache TTL, stale-while-revalidate, the
in-flight guard, every degradation path), `notify_spec.lua` (both halves, with
and without lib.nvim), `health_spec.lua` (every branch against a recorded
`vim.health`), `util/compose_find_spec.lua` (the upward search, all six
filenames, nearest-wins).

**Wiring** — `bindings/usrcmds/routes_spec.lua` checks the route table against a
recording composer (every route has a path/desc/run, no duplicates, ten
namespaces, `--buffer` only where a buffer variant exists, every argument type
registered), then drives the *real* composer and real Ex commands to cover the
argument plumbing that is otherwise unreachable (`command_tail`,
`exec_workdir`, the `--buffer` routing) plus Neovim's own completion. The five
dynamic completion types are covered including the cache, the muted `vim.notify`
during a fetch, and the no-engine case. `bindings/usrcmds/commands_spec.lua` and
`commands_misc_spec.lua` cover all ten command modules: the usage guard, the
no-engine guard, the confirmation gate in front of every destructive verb (and
that a "no" never reaches the engine), which view each result goes to, the
notification wording, and the terminal variants' own argv.

**UI** — `ui/list_views_spec.lua` renders all five list views and presses the
keys for real, which is the only way the `header_offset` pairing gets checked:
three views print a two-line header and pass 2, two print none and pass 0, and
getting that out of step would act on the wrong container without erroring.
`ui/list_actions_wiring_spec.lua` covers the keymap registry (the slugified
action names a user's `keymaps = {…}` spec depends on, moving a key, dropping
one, `keymaps = false`, the shared `q`/`E`/`f`/`?`), the `?` listing built from
what is really bound, the menu gate, `bind_close`, `bulk_confirm_then`, and
`setup_autorefresh`'s timer lifecycle (armed once, stops when the window
closes, closed on `BufWipeout`). `ui/list_actions_spec.lua` (older) covers the
Visual-mode multi-select through real feedkeys. `ui/views_spec.lua` covers the
log/error/inspect views and the live log stream, including that the process is
stopped both by `q` and by the buffer being wiped another way.
`integrations/menu_spec.lua` covers the context-menu builder against the real
`ui.contextmenu`.

**The telescope.nvim front-end** — `telescope/telescope_spec.lua` covers
`telescope/picker.lua`'s `build()` against doubled `telescope.pickers`/
`finders`/`config`/`actions`/`actions.state` (the finder's `entry_maker`, the
default `<CR>` replacing `select_default`, every extra key wired through
`map()`, and that the prompt is closed before any of them fire — or not fired
at all with nothing selected), then `containers.lua`/`images.lua`/`wsl.lua`
against a doubled `sandbox.telescope.picker` (the no-engine and usecase-failure
early-outs, the row formatting including podman's Names-at-the-last-colon
split and the docker `<none>` ref fallback, and every key wired to the right
`container_commands`/`image_commands`/`wsl_commands` call with the right
ref). `telescope._extensions.sandbox` is covered against a doubled
`telescope.register_extension`. None of this touches a real telescope.nvim —
see the seam table above — so it costs nothing towards the "no CI checkout"
reason the front-end used to be skipped entirely for.

### Pinned defects

Marked `BUG:` in the test name, asserted as they behave *today* so a fix breaks
the pin loudly:

1. **`adapters/wsl/list_distros.lua` parses UTF-16LE as if it were text**
   (`adapters/parsing_spec.lua`). The module's comment says "`wsl --list
   --verbose` outputs UTF-16 LE on Windows; vim.system decodes it" — nothing
   decodes it. `text = true` controls newline handling, not the encoding.
   Measured on Windows 11: 388 bytes of which 194 are NUL, and the parser
   produces `name = "\0*\0"`, `state = "\0a\0r\0c\0h\0l\0i\0n\0u\0x\0"` for the
   first row. Effect on the only platform this feature exists for:
   `:Sandbox wsl list` shows mojibake, `DISTRO_NAME` completion offers it, and
   every `:Sandbox wsl <verb> <name>` built from it addresses a distro that does
   not exist. Not fixed here because decoding changes what every WSL command
   returns.
2. **`ui/inspect_view.lua` renders an error list through `vim.inspect` too**
   (`ui/views_spec.lua`). Its own signature is `table | string[]` and its body
   branches on `type(data) == "table"` — but a `string[]` *is* a table, so the
   `else` branch is dead code and the comment on it ("already an error
   string[]") describes something unreachable. Every inspect failure therefore
   arrives as one line of Lua source with the newline shown as a literal `\n`:
   exactly when the raw CLI text matters, it is hardest to read.
3. **`keymaps = false` still binds `<RightMouse>`**
   (`ui/list_actions_wiring_spec.lua`). It does switch off all thirteen key
   actions, but the context-menu trigger is gated on `config.menu.enable`
   alone — so the user who asked for no mappings gets one, and what it opens is
   empty, because the menu is built from the (now empty) set of bound keys.
   Which of the two settings should win is a decision, not an oversight to
   correct silently.

Two asymmetries are pinned as behaviour rather than as defects: podman's
`list_images` returns podman's own JSON objects where docker's normalizes them
(that is why there are two image list views), and `ui/image_list_view_podman.lua`
has no `type(images) ~= "table"` guard where its four siblings do — today
unreachable, because its only caller checks first.

### Deliberately omitted, and why

- **`lua/@types/wsl.lua`, `lua/sandbox/@types/init.lua`** — `---@meta`
  annotations, no runtime code.
- **`lua/sandbox/telescope/*.lua` and `lua/telescope/_extensions/sandbox.lua`**
  no longer belong here — see "The telescope.nvim front-end" above. Only the
  actual rendering of a picker (`pickers.new({}, ...):find()`) stays
  untested, on the same basis as every other real-UI seam in this suite: it
  needs telescope.nvim actually drawing something, which is neither a
  dependency of this plugin nor a CI checkout (only plenary, lib.nvim and
  ui.nvim are).
- **`plugin/commands.lua`, `plugin/health.lua`** — a one-line load guard and a
  `runtime`/`helptags` shim; neither is sourced under
  `-u TESTS/minimal_init.lua` anyway.
- **The real container runtimes.** No spec starts a container, builds an image,
  pulls, prunes or logs in. The argv is the contract; running it would need a
  daemon, a registry and a network, and would be a different kind of test.
- **`ui/highlights.lua`'s `ensure_defined`** beyond its effect — the extmarks it
  colours are asserted in `ui/list_views_spec.lua`; whether
  `DiagnosticOk`/`DiagnosticError` look right in a given colorscheme is not
  something a headless spec can see.
- **The rendering half of the terminal splits** (`exec_in_container`,
  `exec_in_distro`, `container_commands_buffer`) — the argv, the buffer name and
  the buffer reuse are asserted; what a live pty then paints into the window is
  not.
- **`hover.lua`** already has its own spec (`hover_spec.lua`) and was not
  expanded.
