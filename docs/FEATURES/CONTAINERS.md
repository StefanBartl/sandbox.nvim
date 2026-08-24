# Containers

The full container lifecycle, exposed under `:Sandbox container <subcommand>`
(alias `:Sbx container ...`), engine-agnostic across Docker/Podman/nerdctl.

## Container list view

- **Tab:** true
- **Module:** `sandbox/ui/list_view.lua`
- **Usercmds:** `:Sandbox container list`
- **Keymaps:** buffer-local, in the `sandbox.nvim://container-list` scratch
  buffer only

`:Sandbox container list` opens a buffer-local, read-only scratch buffer
(`sandbox.nvim://container-list`) listing every container, running and
stopped, with a `[status]` prefix highlighted by state — green
(`SandboxStatusRunning`), red (`SandboxStatusStopped`), yellow
(`SandboxStatusPaused`), comment-colored (`SandboxStatusOther`) — linked to
`Diagnostic{Ok,Error,Warn}`/`Comment` so it follows the active colorscheme.
Override any of the four highlight groups (e.g. `:hi SandboxStatusRunning
...`) to customize.

### Keymaps

| Key | Action | Key | Action |
|---|---|---|---|
| `<CR>` / `i` | inspect | `n` | rename (prompts) |
| `s` | start | `D` | remove |
| `x` | stop | `l` | logs |
| `X` | kill | `L` | logs (follow) |
| `r` | restart | `e` | exec (shell) |
| `p` | pause | `t` | top |
| `P` | unpause | `T` | stats |
| | | `R` | refresh list |

### Multi-select

Select several lines with `V`/`j`/`j`/... (or any Visual mode), then press
the same key you'd use on a single line — `s`/`x`/`X`/`D`
(start/stop/kill/remove) — to apply it to every selected item at once.
Destructive bulk actions confirm once for the whole batch instead of once
per item.

### Auto-refresh

Set `opts.refresh_interval` (ms) in `setup({})` to have a visible list
buffer re-run its `list` command on a timer instead of relying only on `R`
or a manual re-open. The timer is paused while the buffer isn't shown in
any window, and a buffer-local one-shot `BufWipeout` autocmd (`ui/
list_actions.lua`) stops and closes it when the buffer is wiped, so it
never outlives the buffer it belongs to.

## Container run wizard

Interactively creates and starts a new container, prompting in sequence for
image, name, ports, volumes, and env — no need to hand-assemble a `docker
run` invocation.
- **Module:** `sandbox/core/usecases/containers/run_container.lua`
- **Usercmds:** `:Sandbox container run`

## Start/stop/kill/restart, pause/unpause

Standard lifecycle transitions. `start`/`stop`/`kill`/`restart` accept
`--buffer`/`-b` to stream the CLI's raw output into a scrollable terminal
buffer instead of collapsing it into a single `vim.notify` summary — useful
for verbose operations.
- **Module:** `sandbox/core/usecases/containers/{start,stop,kill,restart,
  pause,unpause}_container.lua`
- **Usercmds:** `:Sandbox container start|stop|kill|restart {id}
  [--buffer|-b]`, `:Sandbox container pause|unpause {id}`

## Rename, remove, prune

`rename` prompts for the new name. `remove` deletes a single stopped
container; `prune` removes all stopped containers at once. Both accept
`--buffer`/`-b`. Destructive actions ask for confirmation first unless
`opts.confirm_destructive = false`.
- **Module:** `sandbox/core/usecases/containers/{rename,remove,
  prune}_container.lua`
- **Usercmds:** `:Sandbox container rename {id} {new-name}`, `:Sandbox
  container remove {id} [--buffer|-b]`, `:Sandbox container prune
  [--buffer|-b]`
- **Config:** `opts.confirm_destructive` (default `true`)

## Logs, including live-following

`logs` shows a one-shot log dump; `logs-follow` streams a container's logs
live (`logs -f`) into a scratch buffer — press `q` in the buffer to stop
following. A buffer-local one-shot `BufWipeout` autocmd (`ui/
log_follow_view.lua`) stops the underlying job if the buffer is wiped
instead of the user pressing `q`, so following never leaves a background
job running against a closed buffer.
- **Module:** `sandbox/core/usecases/containers/get_container_logs.lua`,
  `sandbox/ui/log_view.lua`, `sandbox/ui/log_follow_view.lua`
- **Usercmds:** `:Sandbox container logs {id}`, `:Sandbox container
  logs-follow {id}`

## Exec

`exec` opens an interactive shell inside a running container (defaults to
`opts.default_shell` if none given); `exec-once` runs a single command
non-interactively and shows its output.
### Working directory (2026-08-24)

`workdir=<path>` becomes the engine's `-w`, so a command runs where it
belongs instead of at the image's default directory:

```vim
:Sandbox container exec web bash workdir=/app
:Sandbox container exec-once web workdir=/srv ls -la
```

Closes the flag/option audit's entry. `workdir=` rather than a positional:
every token after the id is part of the command that runs *inside* the
container, so a positional could not be told apart from the command itself.

The flag is inserted **before** the container id in argv. After it, the
engine would hand `-w` to the command running inside the container instead of
consuming it — failing in a way that reads like the command's own error
rather than ours. All three engines spell it the same, and
`tests/sandbox/adapters/exec_workdir_spec.lua` pins the ordering for each.

- **Module:** `sandbox/core/usecases/containers/exec_in_container.lua`,
  `sandbox/adapters/{docker,podman,nerdctl}/containers/exec_in_container.lua`
- **Usercmds:** `:Sandbox container exec {id} [shell] [workdir=<path>]`,
  `:Sandbox container exec-once {id} [workdir=<path>] [command...]`
- **Config:** `opts.default_shell` (default `"sh"`)
- **Tests:** `tests/sandbox/adapters/exec_workdir_spec.lua`

## Stats and top

`stats` gives a one-shot CPU/memory/network/block-IO snapshot; `top` lists
the processes running inside the container.
- **Module:** `sandbox/core/usecases/containers/{stats,top}_container.lua`
- **Usercmds:** `:Sandbox container stats {id}`, `:Sandbox container top
  {id}`

## Copy

Copies a file or directory between the host and a container in either
direction — either side of the `{src} {dest}` pair may be `<id>:<path>`.
- **Module:** `sandbox/core/usecases/containers/cp_container.lua`
- **Usercmds:** `:Sandbox container cp {src} {dest}`

## Inspect view

Renders a container's (or image's/volume's/network's) engine metadata as a
folded, indented `vim.inspect`-style Lua table in a scratch buffer
(`sandbox.nvim://inspect/<id>`) instead of a flat JSON dump —
`foldmethod=indent`, starting at `foldlevel=1`; use `za`/`zo`/`zc` to toggle
sections, `q` to close.
- **Module:** `sandbox/ui/inspect_view.lua`
- **Usercmds:** `:Sandbox container inspect {id}` (and the `inspect`
  subcommand on image/volume/network)
