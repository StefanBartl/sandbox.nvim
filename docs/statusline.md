# Statusline

`require("sandbox.statusline").status()` returns an ambient
`"engine (running/total)"` summary — `"docker (2/5)"` — for people who want to
know whether anything is running without opening a list view.

It is a plain Lua string with no hard dependency on any statusline plugin, the
same soft-dependency philosophy as the rest of sandbox.nvim, and it degrades to
`""` on any failure rather than erroring or notifying. A statusline is not the
place for an error popup.

## Wiring it up

### lualine

```lua
require("lualine").setup({
  sections = { lualine_x = { require("sandbox.statusline").lualine_component } },
})
```

`lualine_component` is `status` under another name — the alias exists so the
lualine spec reads the way lualine specs read.

### heirline, or anything else that takes a function

```lua
{ provider = function() return require("sandbox.statusline").status() end }
```

### The native statusline

```vim
set statusline+=%{v:lua.require('sandbox.statusline').status()}
```

## Caching, and why it is stale on purpose

A statusline redraws many times a second. Asking `docker ps` or `podman ps` on
every redraw is not an option, so the reading is cached for
`status_cache_ttl_ms` (default 3000).

The refresh is **stale-while-revalidate**: `status()` always returns the cached
text immediately and, when that text has gone stale, kicks off a *background*
`ps` whose result replaces the cache for the next redraw. So the first redraw
after expiry shows the previous value and the one after it is current. For an
ambient summary that is the right trade — the alternative is what this used to
do.

It used to call the engine synchronously, which meant a statusline component
froze Neovim for the length of a `docker ps` — 100–500 ms, appreciably more
under Docker Desktop on Windows — every `status_cache_ttl_ms`.

The progress indicator is suppressed for this call (`progress = false`). An
ambient refresh every few seconds would otherwise paint a permanent
`docker ps` handle in the UI.

Only one refresh is ever in flight: a statusline redrawing at speed cannot
stack up one `ps` per redraw while the first is still running.

## The one cost that is left

Spawning a process is synchronous up to the fork/exec, so the redraw that
triggers a refresh still pays roughly 10 ms on Windows (measured; building the
environment next to it is under 1 ms). That is once per TTL, against 100–500 ms
for the full round trip before.

It is also the reason to **raise** `status_cache_ttl_ms` rather than lower it if
the component ever feels sticky. On a slow daemon 3 s is already eager; on a
local one it could be tighter.

## What it reports, and what it does not

- The engine name comes from the same resolution the rest of the plugin uses —
  the first of Podman, Docker and nerdctl whose daemon *answers*, or whatever
  `engine` / `.sandboxrc` pins. See
  [FEATURES/ENGINES.md](FEATURES/ENGINES.md).
- `running` counts containers whose status maps to the running highlight group;
  `total` is every container the engine lists.
- No engine configured, or a daemon that does not answer, is an empty string.
  There is deliberately no "error" state: a statusline that says something is
  wrong every redraw is worse than one that says nothing.

For anything richer than a count, the list views are one keystroke away —
[BINDINGS.md](BINDINGS.md#keymaps).
