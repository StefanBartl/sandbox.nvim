# nvim-containers.nvim
![status](https://img.shields.io/badge/status-beta-orange.svg)
![Lazy.nvim compatible](https://img.shields.io/badge/lazy.nvim-supported-success)
![Neovim](https://img.shields.io/badge/Neovim-0.9+-success.svg)
![Lua](https://img.shields.io/badge/language-Lua-yellow.svg)
![Contributions](https://img.shields.io/badge/contributions-welcome-brightgreen.svg)

> 🔧 Beta stage – under active development. Changes possible.

> Pairs well with [lib.nvim](https://github.com/StefanBartl/lib.nvim), an optional shared-utilities library used here for notifications and cross-platform helpers.

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
- [Disclaimer](#disclaimer)
- [Feedback](#feedback)

---

## Features

- ✅ List running and stopped containers
- ✅ View logs of any container in a buffer
- ✅ Execute shell or one-off commands inside a container
- ✅ Start, stop, kill, inspect, and remove containers
- ✅ Remove all stopped containers (prune)
- ✅ List, pull, remove and prune container images
- ⚡ Automatic engine detection (prefers Podman only if installed, falls back to Docker)
- 🧠 Hexagonal architecture (engine-agnostic, clean ports & adapters)
- 🧩 Easily extendable (Podman, Docker, nerdctl planned)
- 🚀 Unified support for Docker and Podman
- 🩺 Integrated Neovim healthcheck support (`:checkhealth nvim-containers`)
- 🪶 No required Lua dependencies ([lib.nvim](https://github.com/StefanBartl/lib.nvim) is used opportunistically if installed)
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
  "StefanBartl/nvim-containers.nvim",
  event = "VimEnter",
  config = function()
    require("containers").setup({
      -- Optional: explicitly select engine
      -- If omitted, automatic detection will prefer Podman if installed, otherwise Docker
      engine = "podman", -- or "docker"
    })
  end,
}
```

*Load at startup (eager):*
```lua
{
  "StefanBartl/nvim-containers.nvim",
  lazy = false,
  config = function()
    require("containers").setup({})
  end,
}
```

*Load on first use of a command:*
```lua
{
  "StefanBartl/nvim-containers.nvim",
  cmd = {
    "ContainerList", "ContainerLogs", "ContainerExec", "ContainerExecOnce",
    "ContainerStart", "ContainerStop", "ContainerKill",
    "ContainerInspect", "ContainerRemove", "ContainerPrune",
    "ImageList", "ImagePull", "ImageRemove", "ImagePrune"
  },
  config = function()
    require("containers").setup({})
  end,
}
```

ℹ️ Important:
You must call `require("containers").setup({})` to initialize the plugin's configuration.
The engine option is optional.
If omitted, **nvim-containers** will automatically:
    - Prefer **Podman** if installed
    - Fall back to **Docker** otherwise
Explicitly setting engine = "podman" or engine = "docker" will override automatic detection.

---

## Health Check Support

**nvim-containers.nvim** integrates with Neovim's `:checkhealth` system to diagnose common issues.

To run the health check, simply execute:

```vim
:checkhealth nvim-containers
```

The plugin will verify:

- Whether the selected container engine (`podman` or `docker`) is correctly configured
- Whether the corresponding CLI executable is available in your `PATH`

This helps you quickly identify misconfigurations or missing dependencies.

If an unsupported engine is set, or if the CLI binary is missing, clear error messages will be displayed.

---

## Usage

See [`/docs/BINDINGS.md`](./docs/BINDINGS.md) for the full list of user commands (container, image, terminal-buffer and WSL variants).

---

## Supported Engines

| Engine | Status | Notes |
|--------|--------|-------|
| **Podman** | ✅ Supported and stable |
| **Docker** | ✅ Supported and stable |
| **nerdctl** | 🔜 Planned |
| **containerd** | 🔜 Research phase |

Each engine is implemented through clean ports & adapters, fully pluggable.

---

## Development & Contribution

Clone the repository and either symlink or load it into your Neovim runtime path.

See [`docs/CONTRIBUTING.md`](./docs/CONTRIBUTING.md) and [`docs/ADD_USECASE.md`](./docs/ADD_USECASE.md) for guidelines.

### File Layout
- Engine adapters: `lua/containers/adapters/<engine>/`
- Use cases: `lua/containers/core/usecases/`
- User commands: `lua/containers/bindings/usrcmds/` (thin `plugin/*.lua` entrypoints require these)
- UI views: `lua/containers/ui/`

Pull Requests and Issues are very welcome!

---

## Disclaimer

ℹ️ This plugin is under active development – some features are planned or experimental.
Expect changes in upcoming releases.

---

## Feedback

Your feedback is very welcome!

Please use the [GitHub issue tracker](https://github.com/StefanBartl/nvim-containers/issues) to:
- Report bugs
- Suggest new features
- Ask questions about usage
- Share thoughts on UI or functionality

For general discussion, feel free to open a [GitHub Discussion](https://github.com/StefanBartl/nvim-containers/discussions).

If you find this plugin helpful, consider giving it a ⭐ on GitHub — it helps others discover the project.

---
