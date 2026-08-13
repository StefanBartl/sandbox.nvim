# Volumes & Networks

Volume and network management under `:Sandbox volume <subcommand>` /
`:Sandbox network <subcommand>` (aliases `:Sbx volume ...` / `:Sbx network
...`).

## Volume list view

Read-only scratch buffer (`sandbox.nvim://volume-list`) listing all local
volumes.
- **Module:** `sandbox/ui/volume_list_view.lua`
- **Usercmds:** `:Sandbox volume list`
- **Keymaps:** `<CR>`/`i` inspect, `D` remove, `R` refresh list

## Volume create/remove/prune/inspect

`create` makes a new named volume; `remove` deletes one; `prune` removes
all unused volumes; `inspect` opens the folded metadata view.
- **Module:** `sandbox/core/usecases/volumes/{create,remove,prune,
  inspect}_volume.lua`
- **Usercmds:** `:Sandbox volume create {name}`, `:Sandbox volume remove
  {name}`, `:Sandbox volume prune`, `:Sandbox volume inspect {name}`
- **Config:** `opts.confirm_destructive` (default `true`) gates `remove`/
  `prune`

## Network list view

Read-only scratch buffer (`sandbox.nvim://network-list`) listing all local
networks.
- **Module:** `sandbox/ui/network_list_view.lua`
- **Usercmds:** `:Sandbox network list`
- **Keymaps:** `<CR>`/`i` inspect, `D` remove, `R` refresh list

## Network create/remove/prune/inspect

Same shape as volumes: `create`, `remove`, `prune`, `inspect`.
- **Module:** `sandbox/core/usecases/networks/{create,remove,prune,
  inspect}_network.lua`
- **Usercmds:** `:Sandbox network create {name}`, `:Sandbox network remove
  {name}`, `:Sandbox network prune`, `:Sandbox network inspect {name}`
- **Config:** `opts.confirm_destructive` (default `true`) gates `remove`/
  `prune`

## Network connect/disconnect

Attaches or detaches a running container to/from a network by name.
- **Module:** `sandbox/core/usecases/networks/{connect,disconnect}_network.lua`
- **Usercmds:** `:Sandbox network connect {network} {id}`, `:Sandbox
  network disconnect {network} {id}`
