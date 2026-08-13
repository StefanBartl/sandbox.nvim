# Images

Image management under `:Sandbox image <subcommand>` (alias `:Sbx image
...`).

## Image list view

Opens a read-only scratch buffer (`sandbox.nvim://image-list` /
`sandbox.nvim://images`) listing local images.
- **Module:** `sandbox/ui/image_list_view_docker.lua`,
  `sandbox/ui/image_list_view_podman.lua`
- **Usercmds:** `:Sandbox image list`
- **Keymaps:** `<CR>`/`i` inspect, `h` history, `t` tag (prompts for
  target), `D` remove, `R` refresh list

## Pull and push

`pull` fetches an image; `push` sends a local image to a remote registry
(requires prior `registry login`). Both run async and never block the UI —
`pull` additionally accepts `--buffer`/`-b` to stream progress into a
terminal buffer instead of a single completion notify.
- **Module:** `sandbox/core/usecases/images/{pull,push}_image.lua`
- **Usercmds:** `:Sandbox image pull {name} [--buffer|-b]`, `:Sandbox image
  push {name}`

## Build

Builds an image from a Dockerfile/Containerfile, streaming output into a
terminal buffer. `path` defaults to `.`.
- **Module:** `sandbox/core/usecases/images/` (build route),
  `sandbox/bindings/usrcmds/image_commands.lua`
- **Usercmds:** `:Sandbox image build {tag} [path]`

## Tag

Tags a local image with a new `repository:tag`.
- **Module:** `sandbox/core/usecases/images/tag_image.lua`
- **Usercmds:** `:Sandbox image tag {source} {target}`

## Save and load

`save` exports an image to a tarball on disk; `load` imports one back in.
- **Module:** `sandbox/core/usecases/images/{save,load}_image.lua`
- **Usercmds:** `:Sandbox image save {image} {path}`, `:Sandbox image load
  {path}`

## History and inspect

`history` shows an image's layer history; `inspect` opens the same folded
`vim.inspect`-style metadata view used for containers/volumes/networks.
- **Module:** `sandbox/core/usecases/images/history_image.lua`,
  `sandbox/core/usecases/images/inspect_image.lua`
- **Usercmds:** `:Sandbox image history {image}`, `:Sandbox image inspect
  {image}`

## Remove and prune

`remove` deletes a single image; `prune` removes all dangling images
(accepts `--buffer`/`-b`). Confirms first unless `opts.confirm_destructive
= false`.
- **Module:** `sandbox/core/usecases/images/{remove,prune}_image.lua`
- **Usercmds:** `:Sandbox image remove {id}`, `:Sandbox image prune
  [--buffer|-b]`
- **Config:** `opts.confirm_destructive` (default `true`)
