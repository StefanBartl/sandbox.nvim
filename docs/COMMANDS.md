# nvim-containers: Commands Reference

## Container Commands

| Command | Description |
|--------|-------------|
| `:ContainerList` | List all containers |
| `:ContainerLogs <id>` | Show logs |
| `:ContainerExec <id>` | Execute a shell |
| `:ContainerStart <id>` | Start a container |
| `:ContainerStop <id>` | Stop a container |
| `:ContainerKill <id>` | Kill a container |
| `:ContainerInspect <id>` | Inspect metadata |
| `:ContainerRemove <id>` | Remove a container |
| `:ContainerPrune` | Remove all stopped containers |

## Image Commands

| Command | Description |
|--------|-------------|
| `:ImageList` | List local images |
| `:ImagePull <name>` | Pull an image |
| `:ImageRemove <id>` | Remove image |
| `:ImagePrune` | Remove dangling images |
