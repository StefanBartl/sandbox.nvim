# Compose

`:Sandbox compose <subcommand>` (alias `:Sbx compose ...`) operates on the
`docker-compose.yml`/`compose.yml`/`podman-compose.yml` auto-detected in
cwd or an ancestor directory via `vim.fs.find` — the same lookup `docker
compose`/`podman compose` themselves do. There is no id/name argument since
exactly one project exists per detected file.

## Up/down/restart/ps/logs

- **Module:** `sandbox/core/usecases/compose/{up,down,restart,ps,logs}.lua`
- **Usercmds:** `:Sandbox compose up` (start, detached), `:Sandbox compose
  down` (stop and remove), `:Sandbox compose restart`, `:Sandbox compose ps`
  (list services), `:Sandbox compose logs`

`up` starts the compose project detached; `down` stops and removes it;
`restart` restarts it; `ps` lists its services; `logs` shows its logs.
Progress for `up` uses `opts.progress_style` when `lib.nvim` is present.
- **Config:** `opts.progress_style` (default `"auto"`; one of
  `"auto"|"notify"|"statusline"|"fidget"|"float"|"kit"`, no-op without
  `lib.nvim`)

## Services (declared, not running)

- **Module:** `sandbox/util/compose_file.lua` (`M.services`)
- **Usercmd:** `:Sandbox compose services`

`ps` asks the engine what is actually running right now — it needs the
project to be up (or at least the engine reachable) to answer at all.
`services` instead reads the compose file itself, via the same
deliberately minimal YAML decoder [`data.nvim`](https://github.com/StefanBartl/data.nvim)'s
`:YAML` commands use (`lib.lua.yaml`; no anchors, no flow style — see that
module's own doc comment). It answers "what would `up` bring up", with no
engine call, no compose CLI, and no running project required. A compose
file that leans on YAML anchors (`&defaults`/`<<: *defaults`) for shared
service config will not decode correctly here; that comes back as a clear
error rather than a silently incomplete list, so falling back to `docker
compose config --services` for that case is still an option.
