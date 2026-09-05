# Health check

```vim
:checkhealth sandbox
```

Five checks, in order. The first that fails hard stops the rest, because
everything after it would be answering a question that no longer applies.

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
