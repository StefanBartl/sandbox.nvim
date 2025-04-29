# nvim-containers.nvim

Manage your containers (Podman, Docker, and more) directly from Neovim – with clean architecture, pluggable backends, and a TUI-native experience.

---

## Features

- ✅ List running and stopped containers
- ✅ View logs of any container in a buffer
- ✅ Execute shell or one-off commands inside a container
- ✅ Start, stop, kill, inspect, and remove containers
- ✅ Remove all stopped containers (prune)
- ✅ List, pull, remove and prune container images
- 🧠 Hexagonal architecture (engine-agnostic, clean ports & adapters)
- 🧩 Easily extendable (Podman, Docker, nerdctl planned)
- 🚀 Unified support for Docker and Podman
- 🚫 No external Lua dependencies
- 🔥 Plugin-manager friendly (Lazy.nvim, Packer, etc.)

---

## Installation

### lazy.nvim

```lua
{
  "StefanBartl/nvim-containers.nvim",
  event = "VeryLazy", -- or set lazy = false to load on startup
  config = function()
    require("containers").setup({
      engine = "podman", -- or "docker"
    })
  end,
}
```

> ⚠️ If you use `lazy = true`, you must explicitly list all supported commands:
>
> ```lua
> cmd = {
>   "ContainerList", "ContainerLogs", "ContainerExec", "ContainerExecOnce",
>   "ContainerStart", "ContainerStop", "ContainerKill",
>   "ContainerInspect", "ContainerRemove", "ContainerPrune",
>   "ImageList", "ImagePull", "ImageRemove", "ImagePrune"
> }
> ```

---

## Usage

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
| `:ImageList` | List available images |
| `:ImagePull <image>` | Pull an image |
| `:ImageRemove <image-id>` | Remove an image |
| `:ImagePrune` | Prune (remove) dangling images |

---

## Supported Engines

| Engine | Status | Notes |
|--------|--------|-------|
| **Podman** | ✅ Supported and stable |
| **Docker** | ✅ Supported |
| **nerdctl** | 🔜 Planned |
| **containerd** | 🔜 Research phase |

Each engine is implemented through clean ports & adapters, fully pluggable.

---

## Development & Contribution

Clone the repository and either symlink or load it into your Neovim runtime path.

### File Layout
- Engine adapters: `lua/containers/adapters/<engine>/`
- Use cases: `lua/containers/core/usecases/`
- User commands: `lua/containers/plugin/container_commands.lua` and `lua/containers/plugin/image_commands.lua`
- UI views: `lua/containers/ui/`

Pull Requests and Issues are very welcome!

---

## License

[MIT License](./LICENSE)

---

## Disclaimer

⚠️ This is **alpha software**. Expect breaking changes, rough edges, and missing features.
Your feedback is highly appreciated and will help shape the project!

---
