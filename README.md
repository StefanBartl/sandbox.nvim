```
  ███████╗ █████╗ ███╗   ██╗██████╗ ██████╗  ██████╗ ██╗  ██╗
  ██╔════╝██╔══██╗████╗  ██║██╔══██╗██╔══██╗██╔═══██╗╚██╗██╔╝
  ███████╗███████║██╔██╗ ██║██║  ██║██████╔╝██║   ██║ ╚███╔╝
  ╚════██║██╔══██║██║╚██╗██║██║  ██║██╔══██╗██║   ██║ ██╔██╗
  ███████║██║  ██║██║ ╚████║██████╔╝██████╔╝╚██████╔╝██╔╝ ██╗
  ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝
                                                        .nvim
```

![CI](https://github.com/StefanBartl/sandbox.nvim/actions/workflows/ci.yml/badge.svg)
![status](https://img.shields.io/badge/status-beta-orange.svg)
![Lazy.nvim compatible](https://img.shields.io/badge/lazy.nvim-supported-success)
![Neovim](https://img.shields.io/badge/Neovim-0.10+-success.svg)
![Lua](https://img.shields.io/badge/language-Lua-yellow.svg)
![Contributions](https://img.shields.io/badge/contributions-welcome-brightgreen.svg)

> 🔧 Beta stage – under active development. Changes possible.

> Requires [lib.nvim](https://github.com/StefanBartl/lib.nvim) — the user-command layer (`:Sandbox`/`:Sbx`, built on `lib.nvim.usercmd.composer`) and the buffer/window views under `lua/sandbox/ui/` both depend on it directly. `sandbox.notify`/`sandbox.util.run_argv` fall back to plain `vim.notify`/`vim.fn.system` if it's somehow missing, but the plugin as a whole does not run without it. [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) is an *optional* dependency — only needed for the picker extension (`:Telescope sandbox ...`), everything else works without it.

Manage your containers (Podman, Docker, and more) directly from Neovim – with clean architecture, pluggable backends, and a TUI-native experience.

---

- [Features](#features)
- [Installation](#installation)
  - [lazy.nvim](#lazynvim)
- [Health Check Support](#health-check-support)
- [Usage](#usage)
- [Supported Engines](#supported-engines)
- [Development & Contribution](#development--contribution)
  - [File Layout](#file-layout)
- [Roadmap](#roadmap)
- [Disclaimer](#disclaimer)
- [Feedback](#feedback)

---

## Features

- ✅ Full container lifecycle: list, start/stop/kill/restart, pause/unpause,
  rename, remove/prune, inspect, `cp`, an interactive `run` wizard, one-shot
  `stats`/`top`, log viewing — including live-following logs (`logs -f`) —
  and `exec`/`exec-once` to open an interactive shell or run a one-off
  command inside a container
- ✅ Images: list, pull/push (async, non-blocking), tag, build, save/load,
  history, inspect, remove/prune
- ✅ Volumes and networks: list, create, remove/prune, inspect (plus
  connect/disconnect for networks)
- ✅ Compose: `up`/`down`/`restart`/`ps`/`logs` for the `docker-compose.yml`/
  `compose.yml`/`podman-compose.yml` detected in cwd or an ancestor
- ✅ Registry auth: `login`/`logout`, with the password piped via stdin
  (never argv)
- ✅ WSL distro management: list, start/stop/exec, set-default, set-version,
  export/import, shutdown-all
- 🧪 Devcontainer support (`:Sandbox devcontainer build`/`attach`): detects
  `.devcontainer/devcontainer.json`, builds/pulls its image, and runs it
  with the workspace mounted — single-container and `dockerComposeFile`
  shapes only, no features/lifecycle-commands/remoteUser yet
- 🖱️ Buffer-local keymaps in every list view (start/stop/inspect/logs/... on
  the entry under the cursor, plus Visual-mode multi-select for bulk
  actions) and an optional
  [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) picker
  extension (`:Telescope sandbox containers|images|wsl`) as an alternative
  front-end — telescope is not a dependency, only loaded if you opt in
- ⚡ Automatic engine detection (Podman → Docker → nerdctl), a per-project
  `.sandboxrc` override, and runtime switching (`:Sandbox engine set`)
- 🧠 Hexagonal architecture (engine-agnostic, clean ports & adapters)
- 🚀 Unified support for Docker, Podman, and nerdctl (which also covers containerd)
- 🩺 Integrated Neovim healthcheck support (`:checkhealth sandbox`)
- ⌨️ `:Sandbox` (alias `:Sbx`) with `container`/`image`/`volume`/`network`/
  `compose`/`engine`/`registry`/`docs`/`wsl` subcommand trees and `<Tab>`
  completion (built on [lib.nvim](https://github.com/StefanBartl/lib.nvim)'s
  `usercmd.composer` — a required dependency)
- 🔥 Plugin-manager friendly (Lazy.nvim, Packer, etc.)

---

## Installation

**When to use which:**

| Variant | Startup impact | Commands available | When to use |
|---|---|---|---|
| **`lazy = false`** | Loads immediately | Right from the start | Small plugin, want instant availability |
| **`event = "VimEnter"`** | After UI init | After editor UI ready | **Recommended** — minimal startup impact, commands ready right after startup |
| **`cmd = { ... }`** | Deferred | Only when a listed command is first run | Large config, many plugins, rarely-used commands |

### lazy.nvim

*Load after UI init (recommended):*
```lua
{
  "StefanBartl/sandbox.nvim",
  dependencies = { "StefanBartl/lib.nvim" },
  event = "VimEnter",
  config = function()
    require("sandbox").setup({
      -- Optional: explicitly select engine
      -- If omitted, automatic detection will prefer Podman if installed, otherwise Docker
      engine = "podman", -- or "docker" / "nerdctl"
      -- Ask for confirmation before remove/prune/kill (default: true)
      confirm_destructive = true,
      -- Shell used by `container exec` when none is given (default: "sh")
      default_shell = "sh",
      -- ms between list-view auto-refreshes; nil/0 disables (default: nil)
      refresh_interval = nil,
      -- Window placement for list views: "above"|"below"|"left"|"right" (default: "left")
      list_split = "left",
      -- Width/height of list view splits; nil uses Neovim's default
      list_size = nil,
      -- Indicator while pull/push/build/compose/prune run (needs lib.nvim,
      -- no-op without it):
      -- "auto"|"notify"|"statusline"|"fidget"|"float"|"kit" (default: "auto")
      progress_style = "auto",
      -- Right-click context menu on list-view buffers (nvzone/menu, soft
      -- dependency; entries mirror each list's own keymaps). Off
      -- automatically when nvzone/menu isn't installed. See docs/BINDINGS.md.
      menu = { enable = true },
    })
  end,
}
```

*Per-project engine override:* drop a `.sandboxrc` file with an `engine=docker`
or `engine=podman` line in a repo's root to pin that repo to a specific engine
regardless of the global/detected default — useful when a machine has both
installed and one project specifically needs the other.

*Load at startup (eager):*
```lua
{
  "StefanBartl/sandbox.nvim",
  dependencies = { "StefanBartl/lib.nvim" },
  lazy = false,
  config = function()
    require("sandbox").setup({})
  end,
}
```

*Load on first use of a command:*
```lua
{
  "StefanBartl/sandbox.nvim",
  dependencies = { "StefanBartl/lib.nvim" },
  cmd = { "Sandbox", "Sbx" },
  config = function()
    require("sandbox").setup({})
  end,
}
```

ℹ️ Important:
You must call `require("sandbox").setup({})` to initialize the plugin's configuration.
The engine option is optional.
If omitted, **sandbox.nvim** will automatically:
    - Prefer **Podman** if installed
    - Fall back to **Docker** otherwise
Explicitly setting engine = "podman" or engine = "docker" will override automatic detection.

---

## Health Check Support

**sandbox.nvim** integrates with Neovim's `:checkhealth` system to diagnose common issues.

To run the health check, simply execute:

```vim
:checkhealth sandbox
```

The plugin will verify:

- Whether the selected container engine (`podman` or `docker`) is correctly configured
- Whether the corresponding CLI executable is available in your `PATH`

This helps you quickly identify misconfigurations or missing dependencies.

If an unsupported engine is set, or if the CLI binary is missing, clear error messages will be displayed.

---

## Usage

See [`/docs/BINDINGS.md`](./docs/BINDINGS.md) for the full list of user commands (container, image, terminal-buffer and WSL variants), or run `:help sandbox` inside Neovim for the same reference as `:help`-native vimdoc.

---

## Statusline

`require("sandbox.statusline").status()` returns an ambient
`"engine (running/total)"` summary (e.g. `"docker (2/5)"`), cached for 3s so a
statusline redrawing many times a second doesn't shell out on every call. It
degrades to `""` on any failure (daemon down, no engine configured) rather
than erroring. Plain string return with no hard dependency on any statusline
plugin — wire it into lualine:

```lua
require("lualine").setup({
  sections = { lualine_x = { require("sandbox.statusline").lualine_component } },
})
```

or the native statusline: `set statusline+=%{v:lua.require('sandbox.statusline').status()}`.

---

## Telescope extension

An alternative, fuzzy-search front-end to the list-view buffer-local keymaps
— optional, only loaded if you opt in:

```lua
require("telescope").load_extension("sandbox")
```

```vim
:Telescope sandbox containers   " <CR> inspect, <C-s> start, <C-x> stop, <C-r> restart, <C-l> logs, <C-d> remove
:Telescope sandbox images       " <CR> inspect, <C-h> history, <C-d> remove
:Telescope sandbox wsl          " <CR> exec, <C-s> start, <C-x> stop, <C-d> set default
```

---

## Supported Engines

| Engine | Status | Notes |
|--------|--------|-------|
| **Podman** | ✅ Supported and stable | |
| **Docker** | ✅ Supported and stable | |
| **nerdctl** | ✅ Supported and stable | Also covers **containerd** — see below |

Each engine is implemented through clean ports & adapters, fully pluggable.
Pick one at `setup({ engine = "docker" })`/`"podman"`/`"nerdctl"`, override it
per-project via `.sandboxrc`, or switch mid-session with
`:Sandbox engine set docker|podman|nerdctl`.

**On containerd:** there's no separate containerd adapter. containerd
is a low-level daemon with no stable, docker-compatible CLI of its own —
`ctr`, its bundled debug tool, is explicitly documented upstream as
unsuitable for scripting/production use and has a command surface that
doesn't map onto this plugin's docker/podman-shaped ports. `nerdctl` exists
specifically to be *the* docker-compatible CLI for containerd (same JSON
`--format`, compose support, etc.), so the nerdctl adapter above already
covers containerd — a separate adapter would just be nerdctl again
pointed at the same daemon.

---

## Development & Contribution

Clone the repository and either symlink or load it into your Neovim runtime path.

See [`docs/CONTRIBUTING.md`](./docs/CONTRIBUTING.md) and [`docs/ADD_USECASE.md`](./docs/ADD_USECASE.md) for guidelines.

### File Layout
- Engine adapters: `lua/sandbox/adapters/<engine>/`
- Use cases: `lua/sandbox/core/usecases/`
- User commands: `lua/sandbox/bindings/usrcmds/` (registered via `lib.nvim.usercmd.composer`; `plugin/commands.lua` calls `.setup()`)
- UI views: `lua/sandbox/ui/`

### Tests

`tests/` is a [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
busted-style suite; adapters are tested against a faked `run_argv` instead of
a real docker/podman/nerdctl/wsl binary. See [`tests/README.md`](./tests/README.md)
for how to run it locally. [GitHub Actions](./.github/workflows/ci.yml) runs
`luacheck` and the full test suite on every push/PR to `main`.

### Checking docs for drift

[`docs/BINDINGS.md`](./docs/BINDINGS.md) is hand-maintained (it carries prose,
keymap tables, and config notes a route table can't express), so it can drift
from the actual command set as routes are added or renamed. Run
`:Sandbox docs generate` to regenerate
[`docs/GENERATED_COMMANDS.md`](./docs/GENERATED_COMMANDS.md) — a mechanical,
always-accurate dump of every registered route (via
`lib.nvim.usercmd.composer`'s `document()`) — and diff it against
`docs/BINDINGS.md` when adding/changing a command.

Pull Requests and Issues are very welcome!

---

## Roadmap

Looking for ways to contribute, or curious what's planned? See
[`docs/ROADMAP.md`](./docs/ROADMAP.md) for proposed features — more
container/image actions, volume & network support, compose integration, an
interactive TUI-style list view, and more.

---

## Disclaimer

ℹ️ This plugin is under active development – some features are planned or experimental.
Expect changes in upcoming releases.

---

## Feedback

Your feedback is very welcome!

Please use the [GitHub issue tracker](https://github.com/StefanBartl/sandbox.nvim/issues) to:
- Report bugs
- Suggest new features
- Ask questions about usage
- Share thoughts on UI or functionality

For general discussion, feel free to open a [GitHub Discussion](https://github.com/StefanBartl/sandbox.nvim/discussions).

If you find this plugin helpful, consider giving it a ⭐ on GitHub — it helps others discover the project.

---
