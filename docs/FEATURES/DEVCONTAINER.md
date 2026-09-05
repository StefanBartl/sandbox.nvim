# Devcontainer

VS Code-style Dev Containers support under `:Sandbox devcontainer
<subcommand>` (alias `:Sbx devcontainer ...`). **Experimental** — see
[Scope](#scope) below for what it does not cover yet.

## Devcontainer build/attach

- **Module:** `sandbox/core/usecases/devcontainer/build.lua`,
  `sandbox/bindings/usrcmds/devcontainer_commands.lua`
- **Usercmds:** `:Sandbox devcontainer build`, `:Sandbox devcontainer
  attach`

Detects `.devcontainer/devcontainer.json` or `.devcontainer.json` in cwd or
an ancestor directory. JSONC is supported directly — `//` and `/* */`
comments and trailing commas are stripped before parsing, matching what VS
Code's own devcontainer files commonly contain.

`build` resolves the image one of two ways:
- a plain `image` field is pulled directly, or `build.dockerfile` is built
  locally;
- a `dockerComposeFile` project instead delegates to `:Sandbox compose up`.

The resulting container is started with the workspace bind-mounted at
`workspaceFolder`, `forwardPorts` mapped, `containerEnv` passed through, and
`sleep infinity` as the command so it stays up for `attach` afterward —
matching VS Code's own devcontainer CLI, which applies the same override
for images with no long-running default `CMD`. The container is given a
predictable name, `sandbox-devcontainer-<workspace-dir-basename>`, so
`attach` can find it again without tracking any extra state.

`attach` opens a shell in the running devcontainer for the project detected
in the current cwd.

### Scope

Single-container (`image` or `build.dockerfile`) and `dockerComposeFile`
shapes only. No devcontainer "features", lifecycle commands
(`postCreateCommand`, ...), or `remoteUser` support yet.
