# Engines

The hexagonal port/adapter layer that makes "one plugin, three CLIs" possible
— every usecase in `core/usecases/` calls a port interface, never a CLI
binary directly, and one of three adapters (`adapters/docker`,
`adapters/podman`, `adapters/nerdctl`) fulfills it for the currently active
engine.

## Automatic engine detection

On `setup()`, if no engine is configured, sandbox.nvim probes for the CLIs
on `PATH` and picks the first one found, preferring Podman over Docker over
nerdctl.
- **Module:** `sandbox/config/init.lua`
- **Config:** `opts.engine` (default `nil`, meaning auto-detect; explicit
  values `"docker"`/`"podman"`/`"nerdctl"` skip detection entirely)

## Per-project `.sandboxrc` override

A `.sandboxrc` file with an `engine=docker` or `engine=podman` line, dropped
in a repo's root, pins that repo to a specific engine regardless of the
global/detected default — useful on a machine with more than one engine
installed where one project specifically needs the other.

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

`:checkhealth sandbox` reports which engine CLI(s) were found, which one is
active and why, and whether `lib.nvim` (required) and telescope.nvim
(optional) are present.
