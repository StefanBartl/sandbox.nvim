> **Beta stage — active development.** This repository is past its first shape and in
> active use, but the surface is not frozen: breaking changes are still possible. Pin a
> commit or tag if you depend on it.

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
![Status](https://img.shields.io/badge/status-beta-orange)
[![CI](https://github.com/StefanBartl/sandbox.nvim/actions/workflows/ci.yml/badge.svg)](https://github.com/StefanBartl/sandbox.nvim/actions/workflows/ci.yml)

Manage Podman, Docker and nerdctl containers from inside Neovim.

Containers, images, volumes, networks, compose projects, registry auth,
devcontainers and — on Windows — WSL distros all hang off one command tree,
`:Sandbox`, with `<Tab>` completion that resolves live against the running
engine.

---

## Table of contents

- [Documentation](#documentation)
- [What it does](#what-it-does)
- [Around it](#around-it)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quickstart](#quickstart)
- [List views](#list-views)
- [Supported engines](#supported-engines)
- [Integrations](#integrations)
- [Statusline](#statusline)
- [Health check](#health-check)
- [Contributing](#contributing)
- [Feedback](#feedback)
- [License](#license)

---

## Documentation

Start at [docs/README.md](docs/README.md), which says what is where and which
question each page answers.

- [Features](docs/FEATURES/README.md) — ten pages, one per area, each with the reasoning behind the design decision: [containers](docs/FEATURES/CONTAINERS.md), [images](docs/FEATURES/IMAGES.md), [volumes and networks](docs/FEATURES/VOLUMES_NETWORKS.md), [compose](docs/FEATURES/COMPOSE.md), [devcontainers](docs/FEATURES/DEVCONTAINER.md), [the registry](docs/FEATURES/REGISTRY.md), [the engines](docs/FEATURES/ENGINES.md), [WSL](docs/FEATURES/WSL.md), [the UI](docs/FEATURES/UI.md), [the hover integration](docs/FEATURES/HOVER.md).
- [Installation](docs/installation.md) — prerequisites, plugin managers, load triggers.
- [Configuration](docs/configuration.md) — every `setup()` option, its default, and what it trades against.
- [Bindings](docs/BINDINGS.md) — the command tree's full surface, plus keymaps and autocommands.
- [Generated commands](docs/GENERATED_COMMANDS.md) — the same tree as the composer generates it: machine-written, so it cannot drift from the source.
- [Workflow](docs/WORKFLOW.md) — how containers, images and volumes combine into a way of working.
- [Statusline](docs/statusline.md) — the ambient summary, its cache, and how to wire it into lualine or the native statusline.
- [Health check](docs/health.md) — every line `:checkhealth sandbox` can print, and what to do about each.
- [Contributing](docs/CONTRIBUTING.md) — what is expected of a change, and where each layer lives.
- [Adding a use case](docs/add_usecase.md) — the one extension point with a recipe, walked from port to route to spec.

`:help sandbox` is the same reference inside the editor.

---

## What it does

The engine is chosen by asking which one *answers*, not which one is installed
— a stopped Podman VM looks exactly like a broken plugin otherwise. Underneath
it is ports and adapters: every operation is declared once and fulfilled three
times, so adding an engine does not touch the command layer.

| Area | Does |
| --- | --- |
| **Containers** | List, start, stop, kill, restart, pause, unpause, rename, remove, prune, inspect, `cp`, an interactive `run` wizard, one-shot `stats` and `top`, logs including live-following, and `exec` / `exec-once` for a shell or a single command inside a container |
| **Images** | List, pull and push asynchronously, tag, build, save and load, history, inspect, remove, prune |
| **Volumes and networks** | List, create, remove, prune, inspect, plus network connect and disconnect |
| **Compose** | `up`, `down`, `restart`, `ps` and `logs` against the compose file detected in the working directory or an ancestor |
| **Registry** | `login` and `logout`, with the password piped over stdin and never through argv |
| **Devcontainers** | 🧪 `.devcontainer/devcontainer.json` detection, build and attach — single-container and `dockerComposeFile` shapes only |
| **WSL** | Distro list, start, stop, exec, set-default, set-version, export, import and shutdown-all. Windows only, registered only when `wsl.exe` is reachable |
| **Engine handling** | Automatic Podman → Docker → nerdctl detection that skips any whose daemon does not answer, a per-project `.sandboxrc`, and switching mid-session |

One page per area, with the reasoning behind each, is
[docs/FEATURES/](docs/FEATURES/README.md).

---

## Around it

> **[reposcope.nvim](https://github.com/StefanBartl/reposcope.nvim)** — clones
> a repository into a directory, and sandbox picks up the `compose.yml` or
> `.devcontainer/` that repository declares from the working directory or an
> ancestor. So `up` and `devcontainer attach` work in the checkout you just
> made, without configuring a path anywhere.
>
> **[hover.nvim](https://github.com/StefanBartl/hover.nvim)** — an image
> reference in a `Dockerfile` or `compose.yml` reports whether it is pulled,
> how large it is, and which containers came from it.
>
> **[dap.nvim](https://github.com/StefanBartl/dap.nvim)** — the other half of
> running code somewhere that is not your machine.
>
> All of the above are soft: without them everything else works unchanged.
> [lib.nvim](https://github.com/StefanBartl/lib.nvim) and a container engine
> are the real dependencies — see [Requirements](#requirements).

---

## Requirements

| | |
| --- | --- |
| Neovim | **0.10+** |
| [lib.nvim](https://github.com/StefanBartl/lib.nvim) | required, not optional — the `:Sandbox` / `:Sbx` command layer is built on its `usercmd.composer`, and the views under `lua/sandbox/ui/` use its window kit directly |
| A container engine | Podman, Docker or nerdctl on `PATH`, **with its daemon running**. An installed engine whose daemon does not answer is skipped, not used |

Optional, each detected at runtime and degrading to nothing when absent:

| | |
| --- | --- |
| [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) | The same action set as the list views, through a fuzzy finder |
| [hover.nvim](https://github.com/StefanBartl/hover.nvim) | Image references previewed in a `Dockerfile` or `compose.yml` |
| [nvzone/menu](https://github.com/nvzone/menu) | A host for the context-menu entries — see [Integrations](#integrations) |
| `wsl.exe` | The WSL subtree, registered only where it is reachable |

---

## Installation

```lua
-- lazy.nvim
{
  "StefanBartl/sandbox.nvim",
  dependencies = { "StefanBartl/lib.nvim" },
  event = "VimEnter",
  opts = {},
}
```

`opts` is passed to `require("sandbox").setup()`, which has to run for anything
to register. `opts = {}` is a complete configuration: omit `engine` and the
first of Podman, Docker and nerdctl that answers is used. Other plugin managers
and the three load triggers are in
[docs/installation.md](docs/installation.md).

---

## Quickstart

Ask what is there:

```vim
:Sandbox container list
```

That opens a list view — the buffer where most of the work happens, described
[below](#list-views). Then:

```vim
:Sandbox image list        " the same shape, for images
:Sandbox compose up        " the compose file found in cwd or an ancestor
:Sandbox engine set        " switch engine mid-session
```

Every argument completes with `<Tab>`, resolved live against the running engine
rather than from a frozen list.

Verify your setup any time with:

```vim
:checkhealth sandbox
```

---

## List views

`:Sandbox container|image|volume|network list` opens a read-only scratch buffer
where the entry under the cursor is the argument — `s` / `x` / `X` / `r` to
start, stop, kill or restart, `l` / `L` for logs, `e` for a shell, `<CR>` to
inspect, `D` to remove. Select several lines in Visual mode and the same key
applies to all of them, with one confirmation that names what it is about to
remove.

`?` lists what is bound in the buffer you are in, `E` cycles the engine without
leaving it, `f` narrows the list across every field of an entry, and `q`
closes. Every key is remappable — see
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

## Supported engines

| Engine | Status | Notes |
| --- | --- | --- |
| **Podman** | Supported and stable | |
| **Docker** | Supported and stable | |
| **nerdctl** | Supported and stable | Also covers **containerd** |

Pick one with `setup({ engine = "docker" })`, override it per project with a
`.sandboxrc`, or switch mid-session with `:Sandbox engine set`. There is no
separate containerd adapter, and
[docs/FEATURES/ENGINES.md](docs/FEATURES/ENGINES.md#nerdctl--containerd-support)
explains why nerdctl already is one.

---

## Integrations

### Context menu

`sandbox.integrations.menu` contributes context-aware entries in the shape
[nvzone/menu](https://github.com/nvzone/menu) expects. sandbox.nvim has **no**
dependency on `menu` and never opens a context menu itself; a host — typically
your own `<RightMouse>` dispatcher — composes these entries into its own menu.

The entries mirror a list view's own key table one-to-one, so right-click never
offers anything the keyboard does not already provide, and an entry whose
action needs an item under the cursor is omitted when nothing resolves there —
the same rule the keyboard handler enforces. Opt out with
`menu.enable = false`.

### Telescope

`require("telescope").load_extension("sandbox")` registers the pickers shown
under [List views](#list-views). It is an alternative front end to the same
actions, not a second implementation of them.

---

## Statusline

`require("sandbox.statusline").status()` returns an ambient
`"engine (running/total)"` summary — `"docker (2/5)"` — cached and degrading to
`""` on any failure rather than erroring. It has no hard dependency on any
statusline plugin; see [docs/statusline.md](docs/statusline.md) for the lualine
and native wiring, and for why the refresh is deliberately one redraw behind.

---

## Health check

```vim
:checkhealth sandbox
```

Which engine was chosen, why that one, and whether it actually answers — which
is the question behind most reports that the plugin "does nothing".
[docs/health.md](docs/health.md) has every line it can print.

---

## Contributing

Clone the repository and either symlink it or add it to your runtime path.
[docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) has the ground rules and the
project layout; [docs/add_usecase.md](docs/add_usecase.md) walks a single
operation from port to command route to spec.

Pull requests very welcome.

---

## Feedback

Your feedback is very welcome. Use the
[issue tracker](https://github.com/StefanBartl/sandbox.nvim/issues) to report
bugs, suggest features or ask usage questions; anything more open-ended fits a
[discussion](https://github.com/StefanBartl/sandbox.nvim/discussions).

If you find this plugin useful, a ⭐ on GitHub supports its development.

---

## License

MIT — see [LICENSE](LICENSE).
