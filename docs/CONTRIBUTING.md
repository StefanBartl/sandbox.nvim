# Contributing to sandbox.nvim

Thank you for your interest! Bugs, ideas and questions are welcome in the
[issue tracker](https://github.com/StefanBartl/sandbox.nvim/issues); pull
requests very welcome.

## Ground rules

- Lua only, idiomatic Neovim Lua.
- One operation = one file per layer = one route.
- Stay inside the hexagonal architecture: a usecase calls a port, never a CLI
  binary. Adding an engine must not touch the command layer.
- User feedback goes through `sandbox.notify`, not `vim.notify` directly — it
  carries the plugin name, and routes the full error text to `sandbox.logger`
  while `max_error_length` caps what the popup shows.
- 2-space indentation. Descriptive commit messages.

## Project layout

| Path | Contains |
|---|---|
| `lua/sandbox/core/ports/` | The interfaces every engine adapter fulfils |
| `lua/sandbox/core/usecases/` | One operation each, over an injected engine |
| `lua/sandbox/adapters/<engine>/` | Docker, Podman, nerdctl and WSL implementations |
| `lua/sandbox/bindings/usrcmds/` | Handlers and the `:Sandbox` route tree (registered by `plugin/commands.lua`) |
| `lua/sandbox/ui/` | List, inspect, log and error views |
| `lua/sandbox/integrations/` | Soft-dependency bridges (nvzone/menu) |
| `TESTS/` | The spec suite, mirroring `lua/sandbox/`'s paths |

## Adding an operation

[`add_usecase.md`](add_usecase.md) walks `container restart` from port to
adapter to usecase to handler to route to spec, against files that exist in
the repository so every step can be compared with the real thing.

## Tests

`TESTS/` is a [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
busted-style suite. Adapters run against a faked `run_argv` instead of a real
docker/podman/nerdctl/wsl binary, so no engine has to be installed.
[`TESTS/README.md`](../TESTS/README.md) has the invocation.
[GitHub Actions](../.github/workflows/ci.yml) runs `luacheck` and the full
suite on every push and PR to `main`.

## Checking the docs for drift

[`BINDINGS.md`](BINDINGS.md) is hand-maintained — it carries prose, keymap
tables and config notes a route table cannot express — so it can drift from
the actual command set as routes are added or renamed.

`:Sandbox docs generate` rewrites [`GENERATED_COMMANDS.md`](GENERATED_COMMANDS.md)
from the live route table (via `lib.nvim.bindings.usercmd.composer`'s
`document()`). Diff the two whenever you add or change a command. Do not edit
the generated file by hand; regenerate it.

## Workflow

1. Fork the repository.
2. Branch as `feature/<name>`.
3. Make the change, add a spec, update `BINDINGS.md` and regenerate.
4. Open a PR with a clear description of what changed and why.
