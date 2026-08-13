# Registry

Authentication against a container registry, needed before `image push`/
`image pull` against anything private, under `:Sandbox registry
<subcommand>` (alias `:Sbx registry ...`).

## Login/logout with stdin-piped password

`login` prompts for a username (`vim.ui.input`) and password
(`vim.fn.inputsecret`, masked); the password is piped to the engine CLI via
stdin (`--password-stdin`), never passed as an argv element, so it never
shows up in the process list or shell history. Podman (unlike Docker)
requires an explicit `registry` argument — it has no implicit Docker Hub
default. `logout` reverses it.
- **Module:** `sandbox/core/usecases/registry/{login,logout}.lua`
- **Usercmds:** `:Sandbox registry login [registry]`, `:Sandbox registry
  logout [registry]`
