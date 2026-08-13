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
