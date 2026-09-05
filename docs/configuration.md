# Configuration

Everything `require("sandbox").setup({})` accepts. Every field is optional —
`opts = {}` is a complete, working configuration, and the values below are the
defaults it uses.

The authoritative list is
[`lua/sandbox/config/DEFAULTS.lua`](../lua/sandbox/config/DEFAULTS.lua); this
page says what each key is *for*.

## Engine

| Key | Type | Default | What it does |
|---|---|---|---|
| `engine` | `"podman"\|"docker"\|"nerdctl"\|nil` | `nil` | Pin the engine instead of detecting one |

`nil` means detect: the first of Podman, Docker, nerdctl that is on `PATH`
**and answers**. Naming one here skips detection entirely — a named engine is
an instruction, not a guess, and is never probed. Why that distinction earns
its keep is in [FEATURES/ENGINES.md](FEATURES/ENGINES.md#automatic-engine-detection).

### Per-project override: `.sandboxrc`

A file named `.sandboxrc` in a repository's root, containing a single
`engine=docker` (or `podman`/`nerdctl`) line, pins that repository to that
engine regardless of the global or detected default. Useful on a machine with
more than one engine installed where one project specifically needs the other.

Precedence, highest first: `:Sandbox engine set` (this session) → `.sandboxrc`
→ `engine` in `setup()` → detection. `:Sandbox engine get` reports which one
won.

## Behaviour

| Key | Type | Default | What it does |
|---|---|---|---|
| `confirm_destructive` | `boolean` | `true` | Ask before `remove`/`prune`/`kill`. `false` acts immediately |
| `default_shell` | `string` | `"sh"` | Shell `:Sandbox container exec` uses when none is given |
| `max_error_length` | `integer` | `200` | How much of an unrecognized adapter error reaches the notification. The full text always goes to `sandbox.logger`, and the truncated message says where to read it |

## List views

| Key | Type | Default | What it does |
|---|---|---|---|
| `list_split` | `"above"\|"below"\|"left"\|"right"` | `"left"` | Where a list view opens |
| `list_size` | `integer\|nil` | `nil` | Split width (left/right) or height (above/below). `nil` uses Neovim's own sizing |
| `refresh_interval` | `integer\|nil` | `nil` | Milliseconds between automatic re-runs of a visible list's `list` command. `nil`/`0` disables it; refreshing pauses while the buffer is not shown in any window |
| `menu.enable` | `boolean` | `true` | Bind `<RightMouse>` to a context menu mirroring that buffer's own keymaps. Needs [nvzone/menu](https://github.com/nvzone/menu); off by itself when that is not installed |

## Keymaps

| Key | Type | Default | What it does |
|---|---|---|---|
| `keymaps` | `table\|false\|nil` | `nil` | Per-list overrides of the buffer-local keys. `nil` keeps every default, `false` binds none |

Each entry is `action = lhs`, where `lhs` may be one key, a list of keys, or
`false` to drop that action. Action names are the descriptions the views
declare, slugified — "logs (follow)" is `logs_follow`. A name that matches
nothing is reported rather than silently ignored.

```lua
require("sandbox").setup({
  keymaps = {
    list       = { engine = false },               -- drop `E` in every list
    containers = { inspect = "o", remove = false },
    containers_visual = { remove_selection = "X" },
    inspect    = { close = "<Esc>" },              -- the inspect scratch buffer
  },
})
```

The list kinds are `list` (keys every view shares: `close`, `engine`,
`filter`, `help`), `containers`, `images`, `volumes`, `networks`, each with a
`*_visual` counterpart for bulk actions, plus `inspect` and `logs` for the two
scratch views. The full key tables are in [BINDINGS.md](BINDINGS.md#keymaps);
`?` inside any list buffer lists what is *actually* bound, so it stays correct
after a remap.

## Integrations

| Key | Type | Default | What it does |
|---|---|---|---|
| `progress_style` | `"auto"\|"notify"\|"statusline"\|"fidget"\|"float"\|"kit"` | `"auto"` | Indicator while `pull`/`push`/`build`/`compose`/`prune` run |
| `hover` | `boolean` | `true` | Register the request-only image preview with [hover.nvim](https://github.com/StefanBartl/hover.nvim) |

`progress_style` needs [lib.nvim](https://github.com/StefanBartl/lib.nvim) and
is a silent no-op without it. `"auto"` prefers `fidget.nvim` when installed and
falls back to `vim.notify`. `"statusline"` draws nothing and publishes the text
for your own statusline to read via
`require("lib.nvim.progress.styles.statusline").active()`. `"float"` and
`"kit"` open a small window that can be focused and `<Esc>`-ed to abort the
command (`SIGTERM`).

`hover` is a no-op without hover.nvim installed, and never fires on the
automatic trigger — an engine call costs hundreds of milliseconds, so the
contribution is registered `on_request`. See
[FEATURES/HOVER.md](FEATURES/HOVER.md), and [health.md](health.md) for what
`:checkhealth sandbox` says when it is not active.

## Caches

| Key | Type | Default | What it does |
|---|---|---|---|
| `status_cache_ttl_ms` | `integer` | `3000` | How long a statusline reading stays fresh |
| `completion_cache_ttl_ms` | `integer` | `4000` | How long a `<Tab>` completion listing stays cached |

Both trade freshness against how often the engine is asked. Raise them for a
slow daemon (Docker Desktop on Windows), lower them if a stale reading annoys
you.
