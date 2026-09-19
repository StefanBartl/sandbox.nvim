# Health check

```vim
:checkhealth sandbox
```

Several checks, in order. The first that fails hard stops the rest, because
everything after it would be answering a question that no longer applies.

## lib.nvim installed

lib.nvim is a **required** dependency (see [installation.md](installation.md))
— the command layer and every buffer/window view depend on it directly. This
runs first because nothing else below can run without it; its absence is
reported plainly here instead of surfacing as a raw "module not found"
traceback wherever some other section happens to need it first.

| Report | Meaning |
|---|---|
| `ERROR lib.nvim is not installed` | Install it — nothing else in this healthcheck, or the plugin, runs without it |

## Container engine in use

The **resolved** engine — a session override or a `.sandboxrc` line, not the
configured default, because that is what commands actually use.

| Report | Meaning |
|---|---|
| `ERROR No container engine configured (nil)` | Nothing configured and detection found nothing on `PATH` |
| `ERROR Invalid container engine configured: <name>` | `engine` is set to something other than `podman`/`docker`/`nerdctl` |
| `OK Container engine in use: <name>` | — |

## CLI executable found

Whether that engine's binary is reachable on `PATH`.

## The engine answers

The check most worth reading, and the reason this section exists at all.

Being on `PATH` says an engine is *installed*; it says nothing about a daemon
being up. A stopped Podman VM leaves `podman` on `PATH` and every call failing
after ~370 ms — from the outside indistinguishable from a plugin that does
nothing.

| Report | What to do |
|---|---|
| `OK <name> answers` | — |
| `ERROR <name> does not answer -- every command will fail` | Another engine does answer, and the check names it. `:Sandbox engine set <that one>` for this session, or put it in `setup()` to make it permanent |
| `ERROR <name> does not answer -- is its daemon running?` | Nothing answers. Start the daemon, then `:Sandbox engine reset` so the answer is asked again |

## Unknown config keys

`setup()` rejects any key it does not recognize (ERR-50) — checked against the
full nested key set by dotted path — before the merge into defaults, instead
of letting it sit in the active config as a dead field while the option you
meant to set silently keeps its default. Reported here since `setup()` runs
long before `:checkhealth` and a rejected key otherwise leaves no trace.

| Report | Meaning |
|---|---|
| `WARN sandbox.setup(): unknown option '<key>'` | That key was ignored; check for a typo. A close match, if any, is suggested |

## refresh_interval

An invalid `refresh_interval` degrades to its default (auto-refresh off)
rather than raising out of the list views that read it — this is where that
degradation is surfaced, since nothing at the point of use otherwise says
which config key was responsible.

| Report | Meaning |
|---|---|
| `WARN refresh_interval is not a number (<value>)` | List-view auto-refresh is disabled until it is set to a number of milliseconds, or removed |

## list_size

Same shape of problem as `refresh_interval`, for the list-view split's
width/height: an invalid `list_size` degrades to Neovim's own default split
size (via `ui.list_actions.window_opts()`) rather than raising out of
`nvim_win_set_width`/`nvim_win_set_height`, which throw on a non-number or a
non-integral float instead of degrading on their own.

| Report | Meaning |
|---|---|
| `WARN list_size is not a positive integer (<value>)` | The list-view split uses Neovim's default size until it is set to a positive integer, or removed |

## WSL

Informational, never an error. `wsl.exe` on `PATH` is what registers the
`:Sandbox wsl` sub-namespace; its absence is the expected case on Linux and
macOS. If a `wsl` subcommand you expect is not completing, this line says why.

## hover.nvim image preview

The integration can be absent for three unrelated reasons, and none of them
says anything at the point of use — the float simply never opens. Naming which
one is the whole value of reporting it here.

| Report | Meaning |
|---|---|
| `INFO Hover integration disabled (opts.hover = false)` | Turned off in `setup()` |
| `INFO hover.nvim not installed` | Optional dependency absent; image previews unavailable |
| `OK hover.nvim image preview registered` | Ask for it with `:Hover show` |
| `WARN hover.nvim is installed but does not support request-only contributions` | Update hover.nvim. Registering anyway would put a 300–750 ms engine call on the automatic trigger |

## Command tree

Finally, `lib.nvim`'s composer runs its own check over the registered
`:Sandbox` routes.

---

Related: [configuration.md](configuration.md) for `engine` and `hover`,
[FEATURES/ENGINES.md](FEATURES/ENGINES.md) for why detection probes for an
answer instead of trusting `PATH`.
