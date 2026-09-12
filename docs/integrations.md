# Integrations

Everything under `lua/sandbox/integrations/` and `lua/sandbox/telescope/` — soft
bridges to other plugins. sandbox.nvim has no hard dependency on either and
degrades to nothing when they are absent.

## Right-click context menu (nvzone/menu)

Every list-view buffer also binds `<RightMouse>` to a context menu (a soft
dependency) mirroring that buffer's own keymap table one-to-one —
right-click never offers anything the keyboard doesn't already provide.
Wired centrally in `list_actions.set_keymaps` — every list view calls that
one function to bind its rows, so this applies uniformly across container/
image/volume/network lists without per-list wiring. sandbox.nvim has no
dependency on `menu` itself and never opens a context menu on its own
initiative beyond this trigger.
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
