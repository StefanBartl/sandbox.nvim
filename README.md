> **Alpha stage — active development.** This repository is in its development phase — breaking changes are to be expected at any time. Pin a commit or tag if you depend on it.

# sandbox.nvim

```
  ███████╗ █████╗ ███╗   ██╗██████╗ ██████╗  ██████╗ ██╗  ██╗
  ██╔════╝██╔══██╗████╗  ██║██╔══██╗██╔══██╗██╔═══██╗╚██╗██╔╝
  ███████╗███████║██╔██╗ ██║██║  ██║██████╔╝██║   ██║ ╚███╔╝
  ╚════██║██╔══██║██║╚██╗██║██║  ██║██╔══██╗██║   ██║ ██╔██╗
  ███████║██║  ██║██║ ╚████║██████╔╝██████╔╝╚██████╔╝██╔╝ ██╗
  ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝
                                                        .nvim
```

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Neovim](https://img.shields.io/badge/Neovim-0.10%2B-57A143?logo=neovim&logoColor=white)](https://neovim.io)
[![Lua](https://img.shields.io/badge/Lua-5.1%2FLuaJIT-2C2D72?logo=lua&logoColor=white)](https://www.lua.org)
![Status](https://img.shields.io/badge/status-alpha-red)
[![CI](https://github.com/StefanBartl/sandbox.nvim/actions/workflows/ci.yml/badge.svg)](https://github.com/StefanBartl/sandbox.nvim/actions/workflows/ci.yml)

> 💡 Pairs well with [reposcope.nvim](https://github.com/StefanBartl/reposcope.nvim):
> reposcope clones a repository into a directory, and sandbox picks up the
> `compose.yml` / `.devcontainer/` that repository declares from the cwd or an
> ancestor — so `up` and `devcontainer attach` work in the checkout you just
> made without configuring a path anywhere.

Manage Podman, Docker and nerdctl containers from inside Neovim.

Containers, images, volumes, networks, compose projects, registry auth,
devcontainers and (on Windows) WSL distros all hang off one command tree,
`:Sandbox`, with `<Tab>` completion that resolves live against the running
engine. The engine is chosen by asking which one *answers*, not which one is
installed — a stopped Podman VM looks exactly like a broken plugin otherwise.
Underneath it is ports and adapters: every operation is declared once and
fulfilled three times, so adding an engine does not touch the command layer.

---

- [Features](#features)
- [Quickstart](#quickstart)
- [List views](#list-views)
- [Statusline](#statusline)
- [Supported engines](#supported-engines)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [License](#license)

---

## Features

- **Containers** — list, start/stop/kill/restart, pause/unpause, rename,
  remove/prune, inspect, `cp`, an interactive `run` wizard, one-shot
  `stats`/`top`, logs including live-following, and `exec`/`exec-once` for a
  shell or a one-off command inside a container
- **Images** — list, pull/push (async), tag, build, save/load, history,
  inspect, remove/prune
- **Volumes and networks** — list, create, remove/prune, inspect, plus
  network connect/disconnect
- **Compose** — `up`/`down`/`restart`/`ps`/`logs` against the compose file
  detected in cwd or an ancestor
- **Registry** — `login`/`logout`, password piped over stdin, never argv
- **WSL** — distro list, start/stop/exec, set-default, set-version,
  export/import, shutdown-all (Windows only, registered only when `wsl.exe`
  is reachable)
- 🧪 **Devcontainers** — `.devcontainer/devcontainer.json` detection,
  build and attach; single-container and `dockerComposeFile` shapes only
- **List views** — buffer-local keymaps on every list, Visual-mode
  multi-select for bulk actions, and an optional
  [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) picker
  as an alternative front end
- **Engine handling** — automatic Podman → Docker → nerdctl detection that
  skips any whose daemon does not answer, a per-project `.sandboxrc`, and
  runtime switching
- **Hover previews** — with [hover.nvim](https://github.com/StefanBartl/hover.nvim)
  installed, an image reference in a `Dockerfile` or `compose.yml` reports
  whether it is pulled, its size, and any containers from it
- **`:checkhealth sandbox`** — which engine, why that one, and whether it
  answers

One page per area, with the reasoning behind each:
[docs/FEATURES/README.md](docs/FEATURES/README.md).

---

## Quickstart

Requires Neovim **0.10+**, [lib.nvim](https://github.com/StefanBartl/lib.nvim),
and a container engine on `PATH` **with its daemon running**.

```lua
{
  "StefanBartl/sandbox.nvim",
  dependencies = { "StefanBartl/lib.nvim" },
  event = "VimEnter",
  opts = {},
}
```

`opts` is passed to `require("sandbox").setup()`, which has to run for anything
to register. `opts = {}` is a complete configuration: omit `engine` and the
first of Podman, Docker, nerdctl that answers is used.

Then:

```vim
:Sandbox container list
:checkhealth sandbox
```

Other plugin managers, the three load triggers and the full prerequisite list
are in [docs/installation.md](docs/installation.md); every option in
[docs/configuration.md](docs/configuration.md).

`lib.nvim` is required, not optional: the `:Sandbox`/`:Sbx` command layer is
built on its `usercmd.composer` and the views under `lua/sandbox/ui/` use its
window kit directly. telescope.nvim, [nvzone/menu](https://github.com/nvzone/menu)
and hover.nvim are optional and each degrade to nothing when absent.

---

## List views

`:Sandbox container|image|volume|network list` opens a read-only scratch
buffer where the entry under the cursor is the argument — `s`/`x`/`X`/`r` to
start/stop/kill/restart, `l`/`L` for logs, `e` for a shell, `<CR>` to inspect,
`D` to remove. Select several lines in Visual mode and the same key applies to
all of them, with one confirmation that names what it is about to remove.

`?` lists what is bound in the buffer you are in, `E` cycles the engine
without leaving it, `f` narrows the list across every field of an entry, and
`q` closes. Every key is remappable — see
[docs/BINDINGS.md](docs/BINDINGS.md#keymaps).

If you would rather stay in a fuzzy finder, the picker extension is the same
action set through telescope:

```lua
require("telescope").load_extension("sandbox")
```

```vim
:Telescope sandbox containers   " <CR> inspect, <C-s> start, <C-x> stop, <C-r> restart, <C-l> logs, <C-d> remove
:Telescope sandbox images       " <CR> inspect, <C-h> history, <C-d> remove
:Telescope sandbox wsl          " <CR> exec, <C-s> start, <C-x> stop, <C-d> set default
```

---

## Statusline

`require("sandbox.statusline").status()` returns an ambient
`"engine (running/total)"` summary (e.g. `"docker (2/5)"`), cached per
`status_cache_ttl_ms` so a statusline redrawing many times a second does not
shell out on every call. It degrades to `""` on any failure — daemon down, no
engine configured — rather than erroring, and has no hard dependency on any
statusline plugin:

```lua
require("lualine").setup({
  sections = { lualine_x = { require("sandbox.statusline").lualine_component } },
})
```

Or natively: `set statusline+=%{v:lua.require('sandbox.statusline').status()}`.

---

## Supported engines

| Engine | Status | Notes |
|---|---|---|
| **Podman** | Supported and stable | |
| **Docker** | Supported and stable | |
| **nerdctl** | Supported and stable | Also covers **containerd** |

Pick one with `setup({ engine = "docker" })`, override it per project with a
`.sandboxrc`, or switch mid-session with `:Sandbox engine set`. There is no
separate containerd adapter, and
[docs/FEATURES/ENGINES.md](docs/FEATURES/ENGINES.md#nerdctl--containerd-support)
explains why nerdctl already is one.

---

## Documentation

Start at [docs/README.md](docs/README.md), which says what is where and which
question each page answers.

- [Features](docs/FEATURES/README.md) — ten pages, one per area, with the
  reasoning behind each design decision.
- [Installation](docs/installation.md) — prerequisites, plugin managers, load
  triggers.
- [Configuration](docs/configuration.md) — every `setup()` option and its
  default.
- [Bindings](docs/BINDINGS.md) — the command tree's full surface, plus keymaps
  and autocommands.
- [Workflow](docs/WORKFLOW.md) — how the pieces combine into a way of working.
- [Health check](docs/health.md) — every line `:checkhealth sandbox` can print.

`:help sandbox` is the same reference as native vimdoc.

---

## Contributing

Clone the repository and either symlink it or add it to your runtime path.
[docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) has the ground rules and the
project layout; [docs/add_usecase.md](docs/add_usecase.md) walks a single
operation from port to command route to spec.

Bugs, feature ideas and questions are welcome in the
[issue tracker](https://github.com/StefanBartl/sandbox.nvim/issues); anything
more open-ended in [Discussions](https://github.com/StefanBartl/sandbox.nvim/discussions).
Pull requests very welcome.

---

## License

MIT — see [LICENSE](LICENSE).
