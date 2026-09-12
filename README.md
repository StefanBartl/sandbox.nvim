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

Manage Podman, Docker and nerdctl containers from inside Neovim. Containers,
images, volumes, networks, compose projects, registry auth, devcontainers and
— on Windows — WSL distros all hang off one command tree, `:Sandbox`, with
`<Tab>` completion that resolves live against the running engine.

---

## Documentation

Start at [docs/README.md](docs/README.md) — what's where, and which question
each page answers.

**Getting it running**

- [Requirements](docs/installation.md#prerequisites) — Neovim version, `lib.nvim`, and a running container engine.
- [Installation](docs/installation.md) — plugin managers and the three load-trigger variants.
- [Quickstart](docs/quickstart.md) — the first thing to run after installing.
- [Health check](docs/health.md) — every line `:checkhealth sandbox` can print, and what to do about each.

**Using it**

- [Configuration](docs/configuration.md) — every `setup()` option, its default, and what it trades against.
- [Bindings](docs/BINDINGS.md) — the command tree's full surface, plus keymaps, the Telescope picker and autocommands.
- [Generated commands](docs/GENERATED_COMMANDS.md) — the same tree as the composer generates it: machine-written, so it cannot drift from the source.
- [Workflow](docs/WORKFLOW.md) — how containers, images and volumes combine into a way of working.
- [Statusline](docs/statusline.md) — the ambient summary, its cache, and how to wire it into lualine or the native statusline.
- [Integrations](docs/integrations.md) — the right-click context menu and the Telescope picker extension.

**Why it is the way it is**

- [Features](docs/FEATURES/README.md) — ten pages, one per area, each with the reasoning behind the design: containers, images, volumes and networks, compose, devcontainers, the registry, the engines, WSL, the UI, and the hover integration.
- [Around it](docs/around-it.md) — how this plugin's scope relates to reposcope.nvim, hover.nvim and dap.nvim.

**Working on it**

- [Contributing](docs/CONTRIBUTING.md) — what is expected of a change, and where each layer lives.
- [Adding a use case](docs/add_usecase.md) — the one extension point with a recipe, walked from port to route to spec.
- [Feedback](https://github.com/StefanBartl/sandbox.nvim/issues) — bug reports, feature requests, usage questions, or an open-ended [discussion](https://github.com/StefanBartl/sandbox.nvim/discussions).

`:help sandbox` is the same reference inside the editor.

---

## License

sandbox.nvim is released under the [MIT License](https://opensource.org/licenses/MIT) — see [LICENSE](LICENSE).
