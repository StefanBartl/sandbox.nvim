# sandbox.nvim: Bindings Reference

All functionality is exposed via a single user command, `:Sandbox` (short
alias: `:Sbx`), with ten sub-namespaces — `container`, `image`, `volume`,
`network`, `compose`, `engine`, `registry`, `docs`, `devcontainer`, and
(only when `wsl.exe` is reachable) `wsl` — built on
[`lib.nvim.bindings.usercmd.composer`](https://github.com/StefanBartl/lib.nvim) with
`<Tab>` completion at every level: sub-namespace, subcommand name, then
container/image/volume/distro names (resolved live from the active engine, cached
briefly to avoid shelling out on every keystroke). No global keymaps or
autocmds — but see the [Keymaps](#keymaps) section below for the buffer-local
keymaps carried by the list-view scratch buffers.

This file is hand-maintained; run `:Sandbox docs generate` to regenerate
[`GENERATED_COMMANDS.md`](./GENERATED_COMMANDS.md), a mechanical dump of the
live route table, and diff it against this file to catch drift.

## `:Sandbox container <subcommand>` (alias: `:Sbx container ...`)

| Subcommand | Args | Description |
|---|---|---|
| `list` | — | List all containers (running and stopped) |
| `logs` | `{id}` | Show logs for a container |
| `logs-follow` | `{id}` | Stream a container's logs live (`logs -f`); `q` in the buffer stops following |
| `exec` | `{id} [shell] [workdir=<path>]` | Open an interactive shell inside a container. `workdir=` becomes the engine's `-w` |
| `exec-once` | `{id} [workdir=<path>] [command...]` | Run a one-off command and show the output |
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

`workdir=` is written **before** the command on `exec-once`, unlike in
[`GENERATED_COMMANDS.md`](./GENERATED_COMMANDS.md), which prints every `kv`
token last because that is the order the route declares. Both parse, but every
token after the command is part of what runs inside the container, so putting
`workdir=` at the end invites it being read as an argument to that command.
This is the deliberate difference to keep when diffing the two files.

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
`.sandboxrc` (see [configuration.md](configuration.md)) > configured/
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

## `:Sandbox docs <subcommand>` (alias: `:Sbx docs ...`)

| Subcommand | Args | Description |
|---|---|---|
| `generate` | — | Regenerate `docs/GENERATED_COMMANDS.md` from the live route table, for diffing against this (hand-maintained) file |

## `:Sandbox devcontainer <subcommand>` (alias: `:Sbx devcontainer ...`)

Detects `.devcontainer/devcontainer.json` or `.devcontainer.json` in cwd or
an ancestor directory (JSONC: `//`/`/* */` comments and trailing commas are
stripped before parsing) and offers to build/attach, similar to VS Code's
Dev Containers extension. `build` pulls `image` or builds `build.dockerfile`
(or delegates to `:Sandbox compose up` for `dockerComposeFile` projects),
then runs it with the workspace bind-mounted at `workspaceFolder`,
`forwardPorts` mapped, `containerEnv` passed through, and `sleep infinity`
as the command so the container stays up for `attach` — matching VS Code's
own devcontainer CLI, which does the same override for images with no
long-running default CMD. The container gets a predictable name
(`sandbox-devcontainer-<workspace-dir-basename>`) so `attach` can find it.

**Scope**: single-container (`image`/`build.dockerfile`) and
`dockerComposeFile` shapes only. No devcontainer "features", lifecycle
commands (`postCreateCommand`, ...), or `remoteUser` support yet.

| Subcommand | Args | Description |
|---|---|---|
| `build` | — | Build/pull the devcontainer's image and start a container from it |
| `attach` | — | Open a shell in the running devcontainer for the project in cwd |

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

**Multi-select**: select several lines with `V`/`j`/`j`/... (or any Visual
mode), then press the same key you'd use on a single line to apply it to
every selected item — `s`/`x`/`X`/`D` (start/stop/kill/remove) in the
container list, `D` (remove) elsewhere. Destructive bulk actions confirm
once for the whole batch instead of once per item — **and the confirmation
names them**: an earlier version read "Remove 5 containers?" and stopped
there, which is the one question a bulk confirmation must not leave open,
since a Visual selection is easy to get a line wrong and the answer is
irreversible. Capped at ten with an "… and N more" tail, because a prompt
that scrolls is no better than no list.

**Engine switch (`E`)** cycles docker → podman → nerdctl for the session and
re-renders the list. Reaching `:Sandbox engine set podman` previously meant
leaving the buffer, typing the command and re-opening — three steps for
something you decide while looking at the very list that would change.

**Filter (`f`)** narrows the list to matching entries. `/` is Vim's own
buffer search: it finds a line and leaves every other one on screen. `f`
matches across every *field* of an entry — for a container that is name, id,
status and image — so `f redis` finds the container running that image even
though the image is not in the rendered line. An empty query restores the
full list, and filtering always starts from the unfiltered set, so a second
filter widens instead of compounding.

**Every one of these keys is configurable.** They are declared
as named actions through
[`lib.nvim.bindings.keymap`](https://github.com/StefanBartl/lib.nvim), and
the name is the description slugified — "logs (follow)" is `logs_follow`:

```lua
require("sandbox").setup({
  keymaps = {
    list       = { engine = false },              -- drop `E` in every list
    containers = { inspect = "o", remove = false },
    containers_visual = { remove_selection = "X" },
    inspect    = { close = "<Esc>" },              -- the inspect scratch buffer
  },
})
```

`keymaps = false` binds none of them. An lhs may be a list (`inspect = { "<CR>", "i" }`
is the default), and a misspelled action name is reported rather than
silently ignored. `?` and the right-click menu list what is actually bound,
so both stay correct after a remap.

**Right-click context menu**: every list-view buffer also binds
`<RightMouse>` to a context menu (via [nvzone/menu](https://github.com/nvzone/menu),
a soft dependency) mirroring that buffer's own keymap table one-to-one —
right-click never offers anything the keyboard doesn't already provide. If
`nvzone/menu` isn't installed, right-clicking does nothing (one
`:messages` notice per session, not an error). Set `menu = { enable = false }`
in `setup({})` to disable the trigger entirely. Wired centrally in
`sandbox.ui.list_actions.set_keymaps` (see `sandbox.integrations.menu` for
the entry builder), so this applies uniformly to every list type below
without per-list wiring.

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

No global augroup — but two buffer-local, one-shot `BufWipeout` autocmds
exist purely for cleanup, scoped to a single scratch buffer each rather
than persisting globally:

- `ui/list_actions.lua`: stops and closes a list view's `refresh_interval`
  `refresh_interval` timer (see [configuration.md](configuration.md)) when
  its buffer is wiped, so auto-refresh doesn't keep a `luv` timer running
  against a buffer that no longer exists.
- `ui/log_follow_view.lua`: stops the `logs -f` job when a
  `container logs-follow` buffer is wiped, so following doesn't keep a
  background job running after the buffer is gone.

Neither registers a `nvim_create_augroup` or listens outside its own
buffer; both are `once = true` and self-remove after firing.
