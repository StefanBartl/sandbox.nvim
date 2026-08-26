# UI

Everything that draws something on screen: the buffer-local list views, the
inspect view, the telescope picker extension, and the statusline component.

## List views

Each resource kind (container/image/volume/network) opens its own
read-only, buffer-local scratch buffer with buffer-local keymaps for acting
on the entry under the cursor instead of re-typing a command with its
id/name — see CONTAINERS.md/IMAGES.md/VOLUMES_NETWORKS.md for the
per-resource keymap tables. `opts.list_split` controls window placement
(`"above"|"below"|"left"|"right"`), `opts.list_size` its width/height.
- **Module:** `sandbox/ui/list_view.lua`,
  `sandbox/ui/{image,volume,network}_list_view.lua`,
  `sandbox/ui/list_actions.lua`
- **Config:** `opts.list_split` (default `"left"`), `opts.list_size`
  (default `nil`, uses Neovim's default)

## Engine switch and filter from a list view (2026-08-24)

Two buffer-local keys wired centrally in `list_actions.set_keymaps`, so every
list view gets them:

**`E`** cycles docker → podman → nerdctl for the session and re-renders.
Reaching `:Sandbox engine set podman` previously meant leaving the buffer,
typing the command and re-opening — three steps for something you decide
while looking at the very list that would change. Re-rendering matters: a
list belongs to the engine that produced it, so leaving stale rows on screen
after switching would be worse than not offering the key.

The cycle order is a declared list, not `pairs` over the valid-engines set —
cycling has to land in the same place every time.

**`f`** filters the list. `/` is Vim's own buffer search: it finds a line and
leaves every other one on screen. `f` narrows to matching entries and matches
across every *field*, not just the rendered text — `f redis` finds the
container running that image even though the image is not in the line. An
empty query restores the full list; filtering always starts from the
unfiltered set, so a second filter widens rather than compounding.

`f` is offered only where the view supplies a `filter` callback, since
narrowing means re-rendering and only the view knows how.

Also since 2026-08-24: a **bulk destructive confirmation names its items**
(capped at ten, with an "… and N more" tail). It used to read "Remove 5
containers?" and stop there — the one question a bulk confirmation must not
leave open, given a Visual selection is easy to get a line wrong.

- **Module:** `sandbox/ui/list_actions.lua` (`M.set_keymaps`,
  `M.bulk_confirm_then`), `sandbox/bindings/usrcmds/engine_commands.lua`
  (`M.cycle`, `M.ENGINES`)

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
- **Bindings:** [../BINDINGS.md#keymaps](../BINDINGS.md#keymaps)

## Inspect view

Renders a container/image/volume/network's engine metadata as a folded,
indented `vim.inspect`-style Lua table (`sandbox.nvim://inspect/<id>`)
instead of a flat dump — `foldmethod=indent`, starting at `foldlevel=1`;
`za`/`zo`/`zc` toggle sections, `q` closes.
- **Module:** `sandbox/ui/inspect_view.lua`

## Error view

A dedicated scratch buffer for surfacing engine CLI errors that are too
long or too structured for a single `vim.notify` line.
- **Module:** `sandbox/ui/error_view.lua`

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

## Statusline component

An indicator surfaced while long-running operations (pull/push/build/
compose/prune) are in flight, styled per `opts.progress_style`. Backed by
`lib.nvim` when present; a no-op without it.
- **Config:** `opts.progress_style` (default `"auto"`; one of
  `"auto"|"notify"|"statusline"|"fidget"|"float"|"kit"`)

## Status highlighting

The container list's `[status]` prefix is colored by state — green
(`SandboxStatusRunning`), red (`SandboxStatusStopped`), yellow
(`SandboxStatusPaused`), comment-colored (`SandboxStatusOther`) — linked to
`Diagnostic{Ok,Error,Warn}`/`Comment` so it tracks the active colorscheme
without any config. Override any of the four groups directly (e.g. `:hi
SandboxStatusRunning ...`) to customize.
- **Module:** `sandbox/ui/highlights.lua`

## `docs generate`

Regenerates `docs/GENERATED_COMMANDS.md` from the live `lib.nvim.bindings.usercmd.
composer` route table, so the hand-maintained `docs/BINDINGS.md` can be
diffed against it to catch drift between what's documented and what
`:Sandbox <Tab>` actually offers.
- **Module:** `sandbox/bindings/usrcmds/init.lua`
- **Usercmds:** `:Sandbox docs generate`
