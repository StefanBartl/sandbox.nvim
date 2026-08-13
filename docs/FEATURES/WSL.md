# WSL

Windows Subsystem for Linux distro management, under `:Sandbox wsl
<subcommand>` (alias `:Sbx wsl ...`). Registered only when `wsl.exe` is
reachable on `PATH` — checked once, at `require("sandbox.bindings.usrcmds")
.setup()` time, via `wsl_commands.available()` — so the subcommand tree
simply doesn't exist on non-Windows machines or Windows machines without
WSL installed.

## List, start, stop, exec

`list` shows all registered distros; `start`/`stop` start or terminate one
by name; `exec` opens a shell in a distro or runs a one-off command inside
it.
- **Module:** `sandbox/adapters/wsl/{list,start,stop,exec_in}_distro.lua`
- **Usercmds:** `:Sandbox wsl list`, `:Sandbox wsl start {name}`, `:Sandbox
  wsl stop {name}`, `:Sandbox wsl exec {name} [command...]`

## Set default, set version

`set-default` makes a distro WSL's default; `set-version` toggles a distro
between WSL1 and WSL2.
- **Module:** `sandbox/adapters/wsl/set_default_distro.lua`,
  `sandbox/adapters/wsl/set_version_distro.lua`
- **Usercmds:** `:Sandbox wsl set-default {name}`, `:Sandbox wsl
  set-version {name} {1|2}`

## Export and import

`export` writes a distro to a tarball on disk; `import` creates a new
distro from a tarball at a given install path.
- **Module:** `sandbox/adapters/wsl/{export,import}_distro.lua`
- **Usercmds:** `:Sandbox wsl export {name} {path}`, `:Sandbox wsl import
  {name} {install-path} {tar-path}`

## Shutdown all

Shuts down the WSL2 VM and every running distro at once — confirms first
(same `opts.confirm_destructive` gate as other destructive actions).
- **Module:** `sandbox/adapters/wsl/shutdown_all.lua`
- **Usercmds:** `:Sandbox wsl shutdown-all`
- **Config:** `opts.confirm_destructive` (default `true`)
