# sandbox.nvim: Roadmap

This document tracks planned and proposed features for **sandbox.nvim**. It's a
mix of concrete next steps and longer-term ideas — a place to point
contributors at instead of "yeah, there's probably stuff to build."

Nothing here is a promise or a deadline. Items move up when someone (maybe
you!) picks them up. See [`CONTRIBUTING.md`](./CONTRIBUTING.md) and
[`ADD_USECASE.md`](./ADD_USECASE.md) for how a use case is wired through the
hexagonal architecture (port → adapter → usecase → command route → optional
view) before starting on any item below.

Legend: 🔜 planned next · 💡 idea, not started · 🧪 needs design/discussion

---

## 1. Container lifecycle

The `ContainerEngine` port (`core/ports/container_engine.lua`) currently
covers list/logs/exec/start/stop/kill/remove/prune/inspect. Missing
lifecycle actions:

- [ ] 💡 Confirmation prompts for destructive actions (`remove`, `prune`,
      `kill`) — currently these fire immediately once the user command is
      typed. A `vim.ui.select`/`vim.ui.input` confirm step (skippable via
      config, see [§6](#6-configuration)) would prevent fat-finger data loss.

## 2. Images

- [ ] 💡 `tag` — tag an existing image.
- [ ] 💡 `build` — build from a `Dockerfile`/`Containerfile` in the cwd or a
      picked path, streamed into a `--buffer` terminal like `pull` already
      supports.
- [ ] 💡 `save` / `load` — export an image to a tarball and import it back;
      useful for air-gapped or WSL↔host transfers.
- [ ] 💡 `history` — show an image's layer history.
- [ ] 💡 `inspect` — mirror `container inspect` for images (currently
      containers have it, images don't).

## 3. Volumes & networks

Not modeled at all yet — no port methods, no adapters. Both would follow the
same `core/ports/*_engine.lua` → `adapters/<engine>/*` → `core/usecases/*`
pattern as containers/images:

- [ ] 🧪 `Sandbox volume {list,create,remove,inspect,prune}`
- [ ] 🧪 `Sandbox network {list,create,remove,inspect,connect,disconnect}`

These are natural additions to the existing `container`/`image`/`wsl`
sub-namespace pattern in `bindings/usrcmds/`.

## 4. Compose support

- [ ] 💡 Detect `docker-compose.yml` / `compose.yml` / `podman-compose.yml`
      in the cwd (or an ancestor) and expose `Sandbox compose
      {up,down,ps,logs,restart}` scoped to that file.
  - Needs its own port (`core/ports/compose_engine.lua`) since compose is a
    meaningfully different surface than single-container/image commands —
    not just another method bolted onto `ContainerEngine`.
  - `docker compose` (v2 plugin) and `podman-compose` have diverging CLI
    shapes; worth scoping to "detect what's on `PATH`" the same way
    `engine_utils.get_engine()` already prefers Podman over Docker.

## 5. Interactive UI

This is probably the highest-leverage area: today's views
(`ui/list_view.lua`, `ui/image_list_view_*.lua`, `ui/log_view.lua`,
`ui/inspect_view.lua`) are **read-only** scratch buffers — per
`docs/BINDINGS.md`, there are no default keymaps at all, so acting on
something you see in a list means re-typing `:Sandbox container stop <id>`
by hand (tab-completion softens this, but it's still a context switch).

- [ ] 🔜 Buffer-local keymaps in the list views: put the cursor on a
      container/image line and hit a key to start/stop/restart/logs/exec/
      remove/inspect it. This alone would make the list buffers feel like a
      TUI (think `lazygit` / `k9s`) instead of a report you read and then
      act on elsewhere. Doesn't need a new dependency — just keymaps scoped
      to the scratch buffer, resolving the id from the current line.
- [ ] 💡 Auto-refreshing list views (timer or `:Sandbox container list`
      re-run on a configurable interval, or on `BufEnter`/focus) so the
      buffer doesn't go stale the moment you start/stop something from
      elsewhere.
- [ ] 💡 Status icons / highlight groups per container state (running,
      stopped, paused, exited-with-error) instead of the current plain
      `[status] name (id)` text line — easy win with `nvim-web-devicons`
      as an optional soft dependency, matching the `lib.nvim` "required but
      gracefully degrading" pattern already used for `notify`/`run_argv`.
- [ ] 💡 `telescope.nvim` extension: fuzzy-pick a container/image/WSL distro
      and act on it, as an alternative front-end to the tab-completion
      flow. Would live as its own optional module so `telescope.nvim`
      doesn't become a hard dependency.
- [ ] 💡 Multi-select in list views (visual-line select → bulk stop/remove)
      for cleaning up several stopped containers at once without reaching
      for `prune`.
- [ ] 💡 Pretty-printed `inspect` view — currently likely raw JSON; a
      folded/indented Lua-table-style render (or `jq`-style highlighting)
      would make it scannable.
- [ ] 💡 Live log follow (`logs -f` / `--follow`) streamed into the log
      buffer instead of only one-shot snapshots, with a keymap to stop
      following.

## 6. Configuration

`config/DEFAULTS.lua` currently exposes exactly one option (`engine`).
Candidates for `setup({})`:

- [ ] 💡 `confirm_destructive` (bool, default `true`) — gate for the
      confirmation prompts in [§1](#1-container-lifecycle).
- [ ] 💡 `default_shell` — shell used by `container exec` when none is
      given (currently presumably hardcoded per adapter).
- [ ] 💡 `refresh_interval` — for the auto-refreshing list views above.
- [ ] 💡 `list_split` / window placement options — `list_view.lua` hardcodes
      `split = "left"`; making direction/size configurable is a small,
      contained change.
- [ ] 💡 Per-project engine override (e.g. a `.sandboxrc`/`vim.g` project
      var) for repos that specifically need Docker or Podman regardless of
      the global default.

## 7. Engines & architecture

- [ ] 🔜 **nerdctl** adapter — already listed as "planned" in the README's
      supported-engines table; same shape as the existing Docker/Podman
      adapters (`adapters/nerdctl/...engine.lua` + `containers/` +
      `images/`).
- [ ] 💡 **containerd** adapter — listed as "research phase"; likely needs
      `nerdctl` or `ctr` as the actual CLI surface rather than talking to
      the containerd socket directly.
- [ ] 💡 Runtime engine switching — `:Sandbox engine set docker|podman` to
      flip the active engine mid-session instead of only at `setup()` time
      (useful when a machine has both installed).
- [ ] 💡 Async command execution — `util/run_argv.lua` currently only
      exposes `run_blocking_captured` (via `lib.nvim.cross.run_argv`, or a
      blocking `vim.fn.system` fallback). Long-running ops (`pull`, `prune`,
      `build` once it exists) block the UI thread; a
      `vim.system`/`vim.uv.spawn`-backed async path with a callback would
      let `--buffer` streams update live instead of appearing once the
      process exits.

## 8. WSL

Currently `list` / `start` / `stop` / `exec` for registered distros
(`core/usecases/wsl/`, `adapters/wsl/`):

- [ ] 💡 `set-default` — set a distro as the WSL default (`wsl --set-default`).
- [ ] 💡 `set-version` — toggle WSL1/WSL2 per distro.
- [ ] 💡 `export` / `import` — distro backup/restore, mirroring the image
      `save`/`load` idea in [§2](#2-images).
- [ ] 💡 Shutdown-all (`wsl --shutdown`) as a distinct command from
      stopping a single named distro.

## 9. Developer experience & testing

- [ ] 🔜 Automated tests — no test suite currently exists. `plenary.nvim`'s
      busted-style harness is the de facto standard for Neovim plugins and
      would let adapters be tested against a faked `run_blocking_captured`
      without needing Docker/Podman actually installed in CI.
- [ ] 🔜 CI (GitHub Actions) — lint (`luacheck` or `.luarc.json`-driven
      `lua-language-server` check) + the test suite above, on every PR.
- [ ] 💡 `composer.document()` wiring — `ADD_USECASE.md` mentions
      auto-generated docs "if wired up"; actually wiring this would let
      `docs/BINDINGS.md` be generated/verified from the route table instead
      of hand-maintained and prone to drift.

## 10. Stretch / exploratory

- [ ] 🧪 Devcontainer support — detect `.devcontainer/devcontainer.json` and
      offer to build/attach, similar to VS Code's Dev Containers extension.
      Large scope; would likely start as its own port
      (`core/ports/devcontainer_engine.lua`) built on top of the compose
      and container ports rather than a container/image subcommand.
- [ ] 🧪 Registry auth (`login`/`logout`) for private registries, needed
      before `pull`/`push` against anything non-public becomes useful.
- [ ] 🧪 `push` — the natural counterpart to `pull`, absent from the image
      port today.
- [ ] 🧪 Statusline component (lualine/heirline extension) showing engine +
      running container count, for people who want ambient awareness
      without opening a list view.

---

## Contributing an item

Picking something up:

1. Move its checkbox status if useful, or just open a PR — this file isn't
   gospel, it's a backlog.
2. Follow the port → adapter → usecase → route → (optional) view flow in
   [`ADD_USECASE.md`](./ADD_USECASE.md).
3. Implement for **both** Docker and Podman adapters where the port method
   applies to both — half-implemented engine parity is worse than not
   starting.
4. Update [`BINDINGS.md`](./BINDINGS.md) (and the README's feature list, if
   user-facing) alongside the code.
