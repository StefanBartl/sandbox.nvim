# Features

A [`documentation.nvim/docs/FEATURES_FORMAT.md`](https://github.com/StefanBartl/documentation.nvim/blob/main/docs/FEATURES_FORMAT.md)-shaped
catalog of sandbox.nvim's real, currently-shipped feature set — grouped by
the resource kind each feature manages, the same grouping
[`docs/BINDINGS.md`](../BINDINGS.md) already uses for its own command
tables. [`docs/GENERATED_COMMANDS.md`](../GENERATED_COMMANDS.md) is the
mechanically-accurate route dump if a table here ever seems to drift from
what `:Sandbox <Tab>` actually offers.

## Files

- **[ENGINES.md](ENGINES.md)** — the hexagonal port/adapter architecture
  behind "one plugin, three CLIs": automatic Podman → Docker → nerdctl
  detection, per-project `.sandboxrc` pins, runtime `:Sandbox engine set`.
- **[CONTAINERS.md](CONTAINERS.md)** — the full container lifecycle: list,
  start/stop/kill/restart/pause, the interactive `run` wizard, exec,
  logs (including live-following), `cp`, stats/top, rename, remove/prune.
- **[IMAGES.md](IMAGES.md)** — pull/push/build/save/load/tag/history/
  inspect/remove/prune.
- **[VOLUMES_NETWORKS.md](VOLUMES_NETWORKS.md)** — volumes and networks:
  list/create/remove/prune/inspect, plus network connect/disconnect.
- **[COMPOSE.md](COMPOSE.md)** — `up`/`down`/`restart`/`ps`/`logs` for the
  compose file auto-detected in cwd or an ancestor.
- **[REGISTRY.md](REGISTRY.md)** — `login`/`logout` with the password piped
  via stdin, never argv.
- **[DEVCONTAINER.md](DEVCONTAINER.md)** — `.devcontainer/devcontainer.json`
  detection, build/attach.
- **[WSL.md](WSL.md)** — WSL distro management (Windows-only, registered
  only when `wsl.exe` is reachable).
- **[HOVER.md](HOVER.md)** — the request-only hover.nvim preview for an
  image reference under the cursor: pulled or not, size, containers from it,
  and why an engine start must stay off the automatic trigger.
- **[UI.md](UI.md)** — the buffer-local list views (keymaps, multi-select,
  auto-refresh, status highlighting), the inspect view, the telescope
  picker extension, and the statusline component.
