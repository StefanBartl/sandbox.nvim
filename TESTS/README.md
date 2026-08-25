# sandbox.nvim tests

A [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) busted-style
suite. Adapters are tested against a faked `sandbox.util.run_argv`
(`TESTS/sandbox/helpers/fake_run_argv.lua`) instead of a real
docker/podman/nerdctl/wsl binary — no engine needs to be installed to run
these.

## Running locally

Point `PLENARY_PATH` and `LIB_NVIM_PATH` at wherever those two plugins live
in your own setup (e.g. your plugin manager's install dir), then:

```bash
PLENARY_PATH=/path/to/plenary.nvim \
LIB_NVIM_PATH=/path/to/lib.nvim \
nvim --headless --noplugin -u TESTS/minimal_init.lua \
  -c "PlenaryBustedDirectory TESTS/sandbox { minimal_init = 'TESTS/minimal_init.lua' }"
```

A single file:

```bash
PLENARY_PATH=... LIB_NVIM_PATH=... \
nvim --headless --noplugin -u TESTS/minimal_init.lua \
  -c "PlenaryBustedFile TESTS/sandbox/adapters/docker/containers_spec.lua"
```

## Writing a new spec

- One spec file per adapter/module, mirroring `lua/sandbox/...`'s path
  under `TESTS/sandbox/...`.
- `require("tests.sandbox.helpers.fake_run_argv")` to fake the shell-out
  layer; see `TESTS/sandbox/adapters/docker/containers_spec.lua` for the
  pattern (`install()` a fake, `reload()` the module under test so it
  re-requires `run_argv` and picks up the fake, assert on `state.calls`).
- Each spec file runs in its own `nvim --headless` subprocess (plenary
  spawns one per file), so faked modules never leak between files — only
  between `it()` blocks *within* the same file, which is why `reload()`
  exists.
