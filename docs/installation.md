# Installation

## Prerequisites

- Neovim 0.10+
- [`lib.nvim`](https://github.com/StefanBartl/lib.nvim) — **required**. The
  `:Sandbox`/`:Sbx` command layer is built on `lib.nvim.bindings.usercmd.composer`, and
  the buffer/window views under `lua/sandbox/ui/` depend on it directly.
  `sandbox.notify`/`sandbox.util.run_argv` fall back to plain
  `vim.notify`/`vim.fn.system` without it, but the plugin as a whole does not
  run.
- **A container engine on `PATH`** — Podman, Docker or nerdctl. Detection
  prefers Podman if installed, else Docker; `engine` pins one explicitly, and a
  `.sandboxrc` with an `engine=` line pins one per repository.

Optional:

- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) — only for
  the picker extension (`:Telescope sandbox ...`). Everything else works
  without it.
- [nvzone/menu](https://github.com/nvzone/menu) — right-click context menu on
  the list-view buffers. Off automatically when it is not installed.

## lazy.nvim

See the table under [Installation](../README.md#installation) in the README for
which load trigger to pick. The recommended form:

```lua
{
  "StefanBartl/sandbox.nvim",
  dependencies = { "StefanBartl/lib.nvim" },
  event = "VimEnter",
  opts = {},
}
```

## packer.nvim

```lua
use {
  "StefanBartl/sandbox.nvim",
  requires = { "StefanBartl/lib.nvim" }, -- required
  config = function()
    require("sandbox").setup()
  end,
}
```

## vim-plug

```vim
Plug 'StefanBartl/lib.nvim' " required
Plug 'StefanBartl/sandbox.nvim'

lua require("sandbox").setup()
```

## Verifying the installation

```vim
:checkhealth sandbox
:Sandbox containers
```

`:checkhealth sandbox` reports which engines it found and which one detection
settled on — the first thing to check when a command reports nothing at all.
