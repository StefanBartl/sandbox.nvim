# Integrations

Everything under `lua/sandbox/integrations/` and `lua/sandbox/telescope/` —
bridges to other plugins. The context menu goes through
[ui.nvim](https://github.com/WKDSteve/ui.nvim), which sandbox.nvim requires
anyway (see [installation.md](installation.md#prerequisites)); telescope.nvim
is a soft dependency and nothing is loaded without it.

## Right-click context menu (ui.contextmenu)

Every list-view buffer also binds `<RightMouse>` to a context menu
mirroring that buffer's own keymap table one-to-one — right-click never
offers anything the keyboard doesn't already provide. An entry that needs
a row is left out when the cursor is not on one.
Wired centrally in `list_actions.set_keymaps`: every list view calls that
one function to bind its rows, and it hands the buffer to ui.nvim's
`ui.contextmenu.bind_buffer`, so this applies uniformly across container/
image/volume/network lists without per-list wiring. The entries are built
with `ui.contextmenu.entry`/`submenu`.

Drawing the menu is ui.contextmenu's job, not sandbox.nvim's: with its
default `renderer = "auto"` it uses [nvzone/menu](https://github.com/nvzone/menu)
when that is installed and ui.nvim's own `ui.kit.menu` otherwise, so the
menu works without nvzone/menu. sandbox.nvim never opens a context menu on
its own initiative beyond this trigger.
- **Module:** `sandbox/integrations/menu.lua` (`M.items`, `M.submenu`),
  `sandbox/ui/list_actions.lua` (`M.set_keymaps`, trigger binding)
- **Config:** `opts.menu.enable` (default `true`)
- **Bindings:** [BINDINGS.md#keymaps](BINDINGS.md#keymaps)

## Telescope picker extension

An optional alternative front-end to the list-view buffers:
`:Telescope sandbox containers|images|wsl`. telescope.nvim is not a
dependency — nothing under `lua/sandbox/telescope/` is loaded unless the
user explicitly calls `require("telescope").load_extension("sandbox")`.
The picker mirrors `ui/list_actions.lua`'s keymap shape (`{ lhs, desc, fn
}`), so acting on an item from the fuzzy picker stays consistent with the
buffer-local keymaps in the list views rather than being a separate,
diverging command surface.
- **Module:** `sandbox/telescope/picker.lua`,
  `sandbox/telescope/{containers,images,wsl}.lua`
