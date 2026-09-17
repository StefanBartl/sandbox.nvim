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

## Writing a new spec

- One spec file per adapter/module, mirroring `lua/sandbox/...`'s path
  under `TESTS/sandbox/...`.
- `require("TESTS.sandbox.helpers.fake_run_argv")` to fake the shell-out
  layer; see `TESTS/sandbox/adapters/docker/containers_spec.lua` for the
  pattern (`install()` a fake, `reload()` the module under test so it
  re-requires `run_argv` and picks up the fake, assert on `state.calls`).
- Each spec file runs in its own `nvim --headless` subprocess (plenary
  spawns one per file), so faked modules never leak between files — only
  between `it()` blocks *within* the same file, which is why `reload()`
  exists.
