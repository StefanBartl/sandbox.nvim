# `sandbox.nvim`: Roadmap

## `@types`

`lua/sandbox/@types/init.lua` wurde ergänzt (`Sandbox.Engine`, `Sandbox.Config.Options`).
Weitere Typannotationen für Usecase- und Adapter-Signaturen sind noch offen.


## ...in neuen nvim Terminal-Buffer...

Erledigt: `:ContainerStartBuffer`, `:ContainerStopBuffer`, `:ContainerKillBuffer`,
`:ContainerRemoveBuffer`, `:ContainerPruneBuffer`, `:ImagePullBuffer`, `:ImagePruneBuffer`
(siehe `lua/sandbox/bindings/usrcmds/container_commands_buffer.lua`).

---

## Offene Punkte aus dem generellen Plugin-Checklist-Durchlauf (2026-07-05)

- **Which-Key**: Nicht anwendbar — das Plugin definiert keine Keymaps, nur Usrcmds.
  Falls künftig Keymaps sinnvoll werden, gehören sie nach `lua/sandbox/bindings/keymaps/`
  und sollten dann which-key-Gruppen bekommen.
- **Cross-Plattform-Review**: Kurzer Review von `engine_utils.lua`, `adapters/wsl/*.lua`
  und `ui/*.lua` ergab keine harten Plattformannahmen (Pfad-Trenner, shell-spezifisches
  Verhalten). Der WSL-Support ist bereits non-fatal/informational gestaltet
  (`is_executable("wsl")`-Guard), funktioniert also auch auf Linux/macOS ohne Fehler.
- **lib.nvim-Migration**: `sandbox.notify` (optionaler Wrapper um `lib.nvim.nvim.notify`,
  mit Fallback auf `vim.notify`) ist aktuell nur in `engine_utils.lua` und `init.lua`
  eingebunden. Eine vollständige Migration aller ~50 `vim.notify`-Aufrufe in den
  Adaptern/Usecases auf `sandbox.notify` wäre ein separater, rein mechanischer Task
  (siehe `E:/repos/lib.nvim`) — bewusst nicht in diesem Durchlauf gemacht, um den Diff
  klein zu halten.
- **lib.nvim.nvim.usercmd**: Könnte den `pcall`+`vim.notify`-Boilerplate in
  `lua/sandbox/bindings/usrcmds/*.lua` ersetzen. Ebenfalls als separater Folge-Task
  vorgemerkt.
