# Installation

## Prerequisites

- Neovim 0.10+
- [`lib.nvim`](https://github.com/StefanBartl/lib.nvim) — **required**. The
  `:Sandbox`/`:Sbx` command layer is built on `lib.nvim.bindings.usercmd.composer`, and
  the buffer/window views under `lua/sandbox/ui/` depend on it directly.
  `sandbox.notify`/`sandbox.util.run_argv` fall back to plain
  `vim.notify`/`vim.fn.system` without it, but the plugin as a whole does not
  run.
- [`ui.nvim`](https://github.com/StefanBartl/ui.nvim) — **required**.
  `ui.contextmenu`/`ui.kit` (the right-click menu's item builders and
  renderer, plus `kit.input()`'s scripted prompts) are `require()`d
  unconditionally by `lua/sandbox/integrations/menu.lua` and
  `lua/sandbox/ui/list_actions.lua`. [nvzone/menu](https://github.com/nvzone/menu)
  below is a separate, genuinely optional choice of *renderer* for that
  menu — `ui.kit.menu` draws it either way.
- **A container engine on `PATH`, with its daemon running** — Podman, Docker
  or nerdctl. Detection prefers Podman, then Docker, then nerdctl, but skips
  any whose daemon does not answer: an installed engine with a stopped VM is
  not a usable one. `engine` pins one explicitly (and is then never
  second-guessed), and a `.sandboxrc` with an `engine=` line pins one per
  repository.

Optional:

- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) — only for
  the picker extension (`:Telescope sandbox ...`). Everything else works
  without it.
- [nvzone/menu](https://github.com/nvzone/menu) — preferred renderer for the
  right-click context menu on the list-view buffers; `ui.kit.menu` draws it
  otherwise, so the menu itself is not optional (see `ui.nvim` above), only
  this specific look.
- [hover.nvim](https://github.com/StefanBartl/hover.nvim) — an image
  reference under the cursor answers whether it is pulled, its size, and any
  containers from it. Registered request-only, so it never slows the
  automatic trigger; `:checkhealth sandbox` says whether it is active. See
  [docs/FEATURES/HOVER.md](FEATURES/HOVER.md).
- [gitsuite.nvim](https://github.com/StefanBartl/gitsuite.nvim) — a preflight
  check before `:Sandbox devcontainer build` refuses to bake a workspace with
  unresolved merge-conflict markers into an image. Without it, the check is
  skipped and the build proceeds as before.

## lazy.nvim

Three load triggers make sense for a plugin this size. They differ only in
*when* `setup()` runs:

| Trigger | Startup impact | Commands available | When to use |
|---|---|---|---|
| `event = "VimEnter"` | After UI init | Right after startup | **Recommended** — minimal startup cost, nothing to remember |
| `lazy = false` | Loads immediately | From the start | You want it up before the UI is |
| `cmd = { "Sandbox", "Sbx" }` | Deferred | Only once a listed command is first run | Large config, many plugins, and you reach for containers rarely |

Recommended:

```lua
{
  "StefanBartl/sandbox.nvim",
  dependencies = { "StefanBartl/lib.nvim", "StefanBartl/ui.nvim" },
  event = "VimEnter",
  opts = {},
}
```

Eager:

```lua
{
  "StefanBartl/sandbox.nvim",
  dependencies = { "StefanBartl/lib.nvim", "StefanBartl/ui.nvim" },
  lazy = false,
  opts = {},
}
```

On first use of a command:

```lua
{
  "StefanBartl/sandbox.nvim",
  dependencies = { "StefanBartl/lib.nvim", "StefanBartl/ui.nvim" },
  cmd = { "Sandbox", "Sbx" },
  opts = {},
}
```

`opts` is passed to `require("sandbox").setup()`, which has to run for anything
to register — `opts = {}` is enough, and every option it accepts is in
[configuration.md](configuration.md).

## packer.nvim

```lua
use {
  "StefanBartl/sandbox.nvim",
  requires = { "StefanBartl/lib.nvim", "StefanBartl/ui.nvim" }, -- both required
  config = function()
    require("sandbox").setup()
  end,
}
```

## vim-plug

```vim
Plug 'StefanBartl/lib.nvim' " required
Plug 'StefanBartl/ui.nvim' " required
Plug 'StefanBartl/sandbox.nvim'

lua require("sandbox").setup()
```

## Verifying the installation

```vim
:checkhealth sandbox
:Sandbox containers
```

`:checkhealth sandbox` reports which engine is in use, why that one, and
**whether it answers** — the first thing to check when a command reports
nothing at all. An engine that is installed but silent is the case that looks
most like a broken plugin, so it is called out by name. Every line it can
print is explained in [health.md](health.md).
