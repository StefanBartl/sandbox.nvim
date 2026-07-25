# sandbox.nvim: Bindings Reference

All functionality is exposed via a single user command, `:Sandbox` (short
alias: `:Sbx`), with eight sub-namespaces — `container`, `image`, `volume`,
`network`, `compose`, `engine`, `registry`, and (only when `wsl.exe` is
reachable) `wsl` — built on
[`lib.nvim.usercmd.composer`](https://github.com/StefanBartl/lib.nvim) with
`<Tab>` completion at every level: sub-namespace, subcommand name, then
container/image/volume/distro names (resolved live from the active engine, cached
briefly to avoid shelling out on every keystroke). There are no default
keymaps or autocmds.

## `:Sandbox container <subcommand>` (alias: `:Sbx container ...`)

| Subcommand | Args | Description |
|---|---|---|
| `list` | — | List all containers (running and stopped) |
| `logs` | `{id}` | Show logs for a container |
| `logs-follow` | `{id}` | Stream a container's logs live (`logs -f`); `q` in the buffer stops following |
| `exec` | `{id} [shell]` | Open an interactive shell inside a container |
| `exec-once` | `{id} [command...]` | Run a one-off command and show the output |
| `start` | `{id} [--buffer\|-b]` | Start a container |
| `stop` | `{id} [--buffer\|-b]` | Stop a container |
| `kill` | `{id} [--buffer\|-b]` | Kill a container |
| `restart` | `{id} [--buffer\|-b]` | Restart a container |
| `pause` | `{id}` | Pause a running container's processes |
| `unpause` | `{id}` | Resume a paused container's processes |
| `rename` | `{id} {new-name}` | Rename a container |
| `stats` | `{id}` | One-shot CPU/memory/network/block-IO snapshot |
| `top` | `{id}` | List processes running inside a container |
| `cp` | `{src} {dest}` | Copy a file/dir between host and container (either side may be `<id>:<path>`) |
| `run` | — | Interactively create+start a new container (prompts for image, name, ports, volumes, env) |
| `remove` | `{id} [--buffer\|-b]` | Remove a stopped container |
| `prune` | `[--buffer\|-b]` | Remove all stopped containers |
| `inspect` | `{id}` | Inspect container details |

`--buffer` (or its short alias `-b`) streams the CLI's raw output into a
scrollable terminal buffer instead of collapsing it into a `vim.notify`
summary — useful for verbose operations (start/stop/prune). Example:
`:Sandbox container start web --buffer`, `:Sbx container prune -b`.

## `:Sandbox image <subcommand>` (alias: `:Sbx image ...`)

| Subcommand | Args | Description |
|---|---|---|
| `list` | — | List available images |
| `pull` | `{name} [--buffer\|-b]` | Pull an image; runs async (doesn't block the UI) either way — `--buffer` additionally streams progress into a terminal buffer instead of a single completion notify |
| `push` | `{name}` | Push an image to a remote registry (async); requires prior registry auth |
| `tag` | `{source} {target}` | Tag a local image with a new repository:tag |
| `build` | `{tag} [path]` | Build an image from a Dockerfile/Containerfile (streams to a terminal buffer); `path` defaults to `.` |
| `save` | `{image} {path}` | Save (export) an image to a tarball on disk |
| `load` | `{path}` | Load (import) an image from a tarball on disk |
| `history` | `{image}` | Show an image's layer history |
| `inspect` | `{image}` | Inspect detailed information about an image |
| `remove` | `{id}` | Remove an image |
| `prune` | `[--buffer\|-b]` | Remove all dangling images |

## `:Sandbox volume <subcommand>` (alias: `:Sbx volume ...`)

| Subcommand | Args | Description |
|---|---|---|
| `list` | — | List all local volumes |
| `create` | `{name}` | Create a new named volume |
| `remove` | `{name}` | Remove a volume |
| `inspect` | `{name}` | Inspect detailed information about a volume |
| `prune` | — | Remove all unused volumes |

## `:Sandbox network <subcommand>` (alias: `:Sbx network ...`)

| Subcommand | Args | Description |
|---|---|---|
| `list` | — | List all local networks |
| `create` | `{name}` | Create a new named network |
| `remove` | `{name}` | Remove a network |
| `inspect` | `{name}` | Inspect detailed information about a network |
| `connect` | `{network} {id}` | Connect a container to a network |
| `disconnect` | `{network} {id}` | Disconnect a container from a network |
| `prune` | — | Remove all unused networks |

## `:Sandbox compose <subcommand>` (alias: `:Sbx compose ...`)

Scoped to a `docker-compose.yml`/`compose.yml`/`podman-compose.yml`
auto-detected in the cwd or an ancestor directory (via `vim.fs.find`,
same lookup `docker compose`/`podman compose` themselves do). No
id/name argument — there is exactly one project per detected file.

| Subcommand | Args | Description |
|---|---|---|
| `up` | — | Start the compose project, detached |
| `down` | — | Stop and remove the compose project |
| `restart` | — | Restart the compose project |
| `ps` | — | List services in the compose project |
| `logs` | — | Show logs for the compose project |

## `:Sandbox engine <subcommand>` (alias: `:Sbx engine ...`)

Switch the active engine for the rest of this Neovim session instead of only
at `setup({})` time — useful on a machine with both Docker and Podman
installed. Precedence: session override (`engine set`) > per-project
`.sandboxrc` (see the Configuration section of the README) > configured/
detected default.

| Subcommand | Args | Description |
|---|---|---|
| `set` | `{docker\|podman\|nerdctl}` | Switch the active engine for this session |
| `get` | — | Show the currently active engine and why (session override/`.sandboxrc`/config) |
| `reset` | — | Clear the session override, falling back to `.sandboxrc`/config |

## `:Sandbox registry <subcommand>` (alias: `:Sbx registry ...`)

Authentication needed before `push`/`pull` against a private registry.
`login` prompts for username (`vim.ui.input`) and password
(`vim.fn.inputsecret`, masked); the password is piped to the engine via
stdin (`--password-stdin`), never passed as an argv element, so it's never
visible in the process list or shell history. Podman (unlike Docker)
requires an explicit `registry` argument — it has no implicit Docker Hub
default.

| Subcommand | Args | Description |
|---|---|---|
| `login` | `[registry]` | Log in to a registry (prompts for username/password) |
| `logout` | `[registry]` | Log out of a registry |

## `:Sandbox wsl <subcommand>` (alias: `:Sbx wsl ...`)

Only registered when `wsl.exe` is reachable in `PATH` (Windows with WSL
installed; checked once at `require("sandbox.bindings.usrcmds").setup()`
time via `wsl_commands.available()`).

| Subcommand | Args | Description |
|---|---|---|
| `list` | — | List all registered WSL distributions |
| `start` | `{name}` | Start a WSL distro |
| `stop` | `{name}` | Stop (terminate) a WSL distro |
| `exec` | `{name} [command...]` | Open a shell or run a command inside a WSL distro |
| `set-default` | `{name}` | Set a distro as the WSL default |
| `set-version` | `{name} {1\|2}` | Toggle a distro between WSL1/WSL2 |
| `export` | `{name} {path}` | Export a distro to a tarball on disk |
| `import` | `{name} {install-path} {tar-path}` | Import a distro from a tarball |
| `shutdown-all` | — | Shut down the WSL2 VM and all running distros (confirms first) |

## Keymaps

No global keymaps — nothing to map via which-key. The read-only list-view
scratch buffers (`:Sandbox container/image/volume/network list`) do carry
**buffer-local** keymaps so you can act on the entry under the cursor
instead of re-typing a command with its id/name. Press `?` inside any list
buffer for a live reminder; `q` closes it. Set `refresh_interval` (ms) in
`setup({})` to have a visible list buffer re-run its `list` command on a
timer instead of only on `R`/manual re-open; it's paused while the buffer
isn't shown in any window.

### Container list (`sandbox.nvim://container-list`)

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

The `[status]` prefix on each line is highlighted by state — green
(`SandboxStatusRunning`)/red (`SandboxStatusStopped`)/yellow
(`SandboxStatusPaused`)/comment-colored (`SandboxStatusOther`), linked to
`Diagnostic{Ok,Error,Warn}`/`Comment` so it follows your colorscheme. Override
any of the four groups (e.g. `:hi SandboxStatusRunning ...`) to customize.

### Image list (`sandbox.nvim://image-list` / `sandbox.nvim://images`)

| Key | Action |
|---|---|
| `<CR>` / `i` | inspect |
| `h` | history |
| `t` | tag (prompts for target) |
| `D` | remove |
| `R` | refresh list |

### Volume list (`sandbox.nvim://volume-list`)

| Key | Action |
|---|---|
| `<CR>` / `i` | inspect |
| `D` | remove |
| `R` | refresh list |

### Network list (`sandbox.nvim://network-list`)

| Key | Action |
|---|---|
| `<CR>` / `i` | inspect |
| `D` | remove |
| `R` | refresh list |

### Inspect view (`sandbox.nvim://inspect/<id>`)

Opened by any `inspect` action above. Renders the engine's metadata as a
folded, indented `vim.inspect`-style Lua table (`foldmethod=indent`,
starting at `foldlevel=1`) instead of a flat dump — use `za`/`zo`/`zc` to
toggle sections. `q` closes the buffer.

## Autocmds

None defined.
