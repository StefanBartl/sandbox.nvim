# sandbox.nvim: Bindings Reference

All functionality is exposed via a single user command, `:Sandbox` (short
alias: `:Sbx`), with three sub-namespaces — `container`, `image`, and (only
when `wsl.exe` is reachable) `wsl` — built on
[`lib.nvim.usercmd.composer`](https://github.com/StefanBartl/lib.nvim) with
`<Tab>` completion at every level: sub-namespace, subcommand name, then
container/image/distro names (resolved live from the active engine, cached
briefly to avoid shelling out on every keystroke). There are no default
keymaps or autocmds.

## `:Sandbox container <subcommand>` (alias: `:Sbx container ...`)

| Subcommand | Args | Description |
|---|---|---|
| `list` | — | List all containers (running and stopped) |
| `logs` | `{id}` | Show logs for a container |
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
| `pull` | `{name} [--buffer\|-b]` | Pull an image |
| `tag` | `{source} {target}` | Tag a local image with a new repository:tag |
| `remove` | `{id}` | Remove an image |
| `prune` | `[--buffer\|-b]` | Remove all dangling images |

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

## Keymaps

None defined — nothing to map via which-key.

## Autocmds

None defined.
