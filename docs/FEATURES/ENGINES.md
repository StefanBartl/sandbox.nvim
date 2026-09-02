# Engines

The hexagonal port/adapter layer that makes "one plugin, three CLIs" possible
— every usecase in `core/usecases/` calls a port interface, never a CLI
binary directly, and one of three adapters (`adapters/docker`,
`adapters/podman`, `adapters/nerdctl`) fulfills it for the currently active
engine.

## Automatic engine detection

If no engine is configured, sandbox.nvim picks one itself: the first CLI on
`PATH` **that actually answers**, preferring Podman over Docker over nerdctl.

**Both halves of that sentence matter, and the second was missing until
2026-09-02.** Being on `PATH` says an engine is *installed*; it says nothing
about a daemon being up. On a machine with Podman Desktop installed but its
Linux VM stopped, `podman` is on `PATH`, wins the preference order, and every
call fails after ~370 ms — while a running Docker engine sits beside it and is
never asked. Nothing said so, because a failed lookup and an empty answer look
identical from the outside.

**The cost is paid lazily and once.** A liveness probe is a process start
(measured at 380–640 ms, and no phrasing of the question is cheaper — the
connect *is* the cost), so it does not run at `setup()`: startup keeps the
`PATH`-only pick, and the probe happens the first time something actually
reaches for the engine. The answer is then remembered for the session.
`:Sandbox engine reset` forgets it, which is what to run after starting a
daemon mid-session.

**An engine you name is never probed.** `opts.engine`, a `.sandboxrc` line and
`:Sandbox engine set` are instructions, not guesses; only detection asks
whether its choice can answer. If nothing answers, detection falls back to the
first installed engine, so the error you eventually see names a real engine —
"podman is not running" is actionable, "no engine" on a machine with two
installed is not.

- **Module:** `sandbox/engine_utils.lua` (`get_live_engine`, `responds`),
  resolved in `sandbox.resolve_engine_name`
- **Config:** `opts.engine` (default `nil`, meaning auto-detect; explicit
  values `"docker"`/`"podman"`/`"nerdctl"` skip detection entirely)
- **Usercmds:** `:checkhealth sandbox` says whether the engine in use answers,
  and names one that does when it does not

## Per-project `.sandboxrc` override

A `.sandboxrc` file with an `engine=docker` or `engine=podman` line, dropped
in a repo's root, pins that repo to a specific engine regardless of the
global/detected default — useful on a machine with more than one engine
installed where one project specifically needs the other.

- **Module:** `util/project_config.lua` (`read_engine_override`), consumed by `bindings/usrcmds/engine_commands.lua`
- **Config:** a `.sandboxrc` in the repo root, `engine=docker|podman|nerdctl`
- **Usercmds:** `:Sandbox engine get` reports which source won

## Runtime engine switching

`:Sandbox engine set {docker|podman|nerdctl}` switches the active engine for
the rest of the Neovim session without restarting or re-running `setup()`.
`:Sandbox engine get` reports the currently active engine and why (session
override vs. `.sandboxrc` vs. configured/detected default); `:Sandbox engine
reset` clears the session override, falling back to `.sandboxrc`/config.
Precedence: session override > `.sandboxrc` > configured/detected default.
- **Module:** `sandbox/bindings/usrcmds/engine_commands.lua`
- **Usercmds:** `:Sandbox engine set {name}`, `:Sandbox engine get`,
  `:Sandbox engine reset` (aliases: `:Sbx engine ...`)

## nerdctl / containerd support

nerdctl is a first-class third adapter alongside Docker and Podman, which
also covers containerd-backed setups without a separate integration.
- **Module:** `sandbox/adapters/nerdctl/`

## Integrated healthcheck

- **Module:** `health.lua`
- **Usercmds:** `:checkhealth sandbox`

`:checkhealth sandbox` reports which engine CLI(s) were found, which one is
active and why, and whether `lib.nvim` (required) and telescope.nvim
(optional) are present.
