# nvim-containers: Bindings Reference

All functionality is exposed via user commands. There are no default keymaps
or autocmds.

## User Commands

### Container commands

| Command | Description |
|---------|-------------|
| `:ContainerList` | List all containers (running and stopped) |
| `:ContainerLogs <id>` | Show logs for a container |
| `:ContainerExec <id> [shell]` | Open interactive shell inside container |
| `:ContainerExecOnce <id> <command>` | Run one-off command and show output |
| `:ContainerStart <id>` | Start a container |
| `:ContainerStop <id>` | Stop a container |
| `:ContainerKill <id>` | Kill a container |
| `:ContainerInspect <id>` | Inspect container details |
| `:ContainerRemove <id>` | Remove a container |
| `:ContainerPrune` | Prune (remove) all stopped containers |

### Container commands (terminal-buffer variants)

Stream CLI output directly into a scrollable terminal buffer instead of `vim.notify`.

| Command | Description |
|---------|-------------|
| `:ContainerStartBuffer <id>` | Start a container, stream output into a terminal buffer |
| `:ContainerStopBuffer <id>` | Stop a container, stream output into a terminal buffer |
| `:ContainerKillBuffer <id>` | Kill a container, stream output into a terminal buffer |
| `:ContainerRemoveBuffer <id>` | Remove a container, stream output into a terminal buffer |
| `:ContainerPruneBuffer` | Prune stopped containers, stream output into a terminal buffer |
| `:ImagePullBuffer <image>` | Pull an image, stream output into a terminal buffer |
| `:ImagePruneBuffer` | Prune dangling images, stream output into a terminal buffer |

### Image commands

| Command | Description |
|---------|-------------|
| `:ImageList` | List available images |
| `:ImagePull <image>` | Pull an image |
| `:ImageRemove <image-id>` | Remove an image |
| `:ImagePrune` | Prune (remove) dangling images |

### WSL commands

Only registered when `wsl.exe` is available in `PATH` (i.e. on Windows with WSL installed).

| Command | Description |
|---------|-------------|
| `:WslList` | List all registered WSL distributions |
| `:WslStart <distro-name>` | Start a WSL distro |
| `:WslStop <distro-name>` | Stop (terminate) a WSL distro |
| `:WslExec <distro-name> [command...]` | Open a shell or run a command inside a WSL distro |

## Keymaps

None defined — nothing to map via which-key.

## Autocmds

None defined.
