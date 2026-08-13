# Workflow — getting real use out of sandbox.nvim day to day

Every feature here is documented on its own elsewhere (`docs/FEATURES/`,
`docs/BINDINGS.md`). This is the different question: once several features
exist, *how do they actually combine* into something worth reaching for
regularly, instead of typing raw `docker`/`podman` in a terminal split.

## Pick a list view over remembering ids

The single biggest habit change this plugin asks for: stop copying
container ids out of `docker ps` and into commands. `:Sandbox container
list` gives you a live buffer where `s`/`x`/`X`/`r` (start/stop/kill/
restart), `l`/`L` (logs/logs-follow), `e` (exec), `<CR>`/`i` (inspect) all
act on the entry *under the cursor* — the id never has to leave the buffer.
The same shape applies to `image`/`volume`/`network list`. If you'd rather
stay in a fuzzy-finder instead of a scratch buffer, `:Telescope sandbox
containers|images|wsl` is the same action set through a different front
end — pick whichever matches how you already navigate, not both at once
for the same task.

## Multi-select before you reach for a shell loop

Selecting several lines with `V`/`j`/`j`/... in a list buffer and then
pressing `x` (or `D`, `X`, `s`) applies that action to every selected
container in one confirmed batch. This is the direct replacement for `docker
stop $(docker ps -q --filter ...)` — no shell quoting, one confirmation
prompt for the whole batch instead of per-container, and it works
identically for containers, volumes, and networks (whichever the current
list buffer holds).

## `--buffer`/`-b` when you need to watch, not just know the result

Most mutating commands (`start`/`stop`/`kill`/`restart`/`remove`/`prune`
container, `pull`/`prune` image) default to collapsing their result into a
single `vim.notify`. Append `--buffer`/`-b` when the operation is slow or
verbose enough that you want to watch it stream — `image build` and
`image pull --buffer` are the two you'll reach for this on most; a
one-line `stop` rarely needs it. `logs-follow` is the one command that's
*always* streaming (no flag needed) — `q` in that buffer stops the
follow and cleans up the background job on its own.

## Compose and devcontainer both key off cwd, not off a name you pass

`:Sandbox compose <subcommand>` and `:Sandbox devcontainer <subcommand>`
take **no** id/name argument — both auto-detect their target file
(`compose.yml`/`docker-compose.yml`/`podman-compose.yml`, or
`.devcontainer/devcontainer.json`) by walking up from cwd. The practical
consequence: `cd` (or `:cd`) into the right project root *before* running
either, not after — running `:Sandbox compose up` from the wrong directory
either fails to find a file or, worse, finds a different project's file
further up the tree. If a devcontainer project itself uses
`dockerComposeFile`, `:Sandbox devcontainer build` transparently delegates
to `compose up` — you don't need to run both yourself.

## One engine, but check which one before assuming

On a machine with both Docker and Podman installed, don't assume which one
sandbox.nvim picked — run `:Sandbox engine get` once per session (or after
switching projects) to see the active engine and why (session override vs.
`.sandboxrc` vs. detected default). `:Sandbox engine set podman` only
affects the current session; a project that always needs a specific engine
regardless of session state should get a `.sandboxrc` with an `engine=`
line committed alongside it instead, so nobody on the team has to remember
to switch manually.

## `registry login` before the first `push`, per registry

`image push` requires prior `registry login` for that registry — Podman
additionally requires you name the registry explicitly (`:Sandbox registry
login registry.example.com`), it has no implicit Docker Hub default the
way Docker does. The password prompt (`vim.fn.inputsecret`, masked) pipes
straight to the engine over stdin, so it's safe to run this in a shared
terminal recording without the password leaking into scrollback or shell
history — but a login only lasts as long as the underlying engine's own
credential store does, so a `push` failing with an auth error after a long
gap is usually a stale login, not a plugin bug.

## `:Sandbox docs generate` after touching the command tree

If you're contributing a new usecase (see `docs/ADD_USECASE.md`), the last
step before opening a PR is `:Sandbox docs generate` to regenerate
`docs/GENERATED_COMMANDS.md` from the live route table, then diff it
against the hand-maintained `docs/BINDINGS.md` you just edited. This is the
fast "did I actually wire the route the way I described it" check — much
faster than launching a fresh Neovim and typing `:Sandbox <Tab>` through
every level by hand.

## WSL commands only exist if you're on the right machine

`:Sandbox wsl ...` is registered conditionally, based on whether `wsl.exe`
is reachable at `setup()` time — on Linux/macOS, or a Windows box without
WSL, the subcommand tree simply isn't there, and `:Sandbox wsl<Tab>` will
show nothing rather than erroring per-call. Don't build a keymap or script
around `:Sandbox wsl` unless you know the target machine has WSL; check
`:checkhealth sandbox` if a `wsl` subcommand you expect isn't completing.
