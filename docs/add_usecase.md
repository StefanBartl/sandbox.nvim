# Adding a use case

The one extension point with a recipe. A "use case" is a single operation —
restart a container, tag an image — wired through the hexagonal architecture
from port to command route.

Worked example throughout: `container restart`, which already exists, so every
file named below can be opened and compared against what this page claims.

---

## 1. Declare it on the port

The port is the interface every engine adapter has to fulfil. Adding a method
here is what makes the operation exist at all.

**File:** `lua/sandbox/core/ports/container_engine.lua`
(or `compose_engine.lua` / `wsl_engine.lua`)

```lua
--- @param id string
--- @param _on_done? fun(ok: boolean, err: string|nil)
restart_container = function(id, _on_done)
  error(id .. ": restart_container not implemented.")
end,
```

The body is the *unimplemented* case: an adapter that forgets the method fails
loudly and by name instead of silently returning `nil`. Prefix unused
parameters with `_` so luacheck stays quiet.

**Sync or async?** Short mutating calls (`start`, `stop`, `rename`) may return
`ok, err` directly. The read-heavy ones (`list_containers`, `get_logs`,
`inspect_container`, `stats_container`, `top_container`) take an optional
`on_done` and go through `run_async_captured` when given one — those are the
calls long enough to be felt (100–500 ms, more under Docker Desktop on
Windows).

## 2. Implement it in every adapter

There are three: `docker`, `podman`, `nerdctl`. Each has its own file for the
operation, and `TESTS/sandbox/adapters/engine_parity_spec.lua` fails if a
top-level aggregator does not expose everything its sub-aggregators define —
so a method added to one engine and forgotten in another is caught.

**File:** `lua/sandbox/adapters/podman/containers/restart_container.lua`

The file returns a **module table**, and the function inside it carries the
port's name:

```lua
---@module 'sandbox.adapters.podman.containers.restart_container'
--- Podman Adapter: Function to restart a container

local M = {}

--- Restart a specific container
--- @param container_id string: ID or name of the container to restart
--- @param on_done? fun(ok: boolean, err: string|nil)
function M.restart_container(container_id, on_done)
  local cmd = { "podman", "restart", container_id }

  vim.fn.jobstart(cmd, {
    on_exit = function(_, code, _)
      vim.schedule(function()
        if on_done then
          on_done(code == 0, code == 0 and nil or ("exit code " .. code))
        end
      end)
    end,
  })
end

return M
```

Shell out through `sandbox.util.run_argv` (`run_blocking_captured` /
`run_async_captured`) or `vim.fn.jobstart` — never `vim.fn.system` with a
string, and never a shell. Prefer `run_argv`: it is what the test suite fakes
(`TESTS/sandbox/helpers/fake_run_argv.lua`), so an adapter that uses it is
testable without a container engine installed, and it is where the completed
spawn environment and the progress indicator are wired in.

Then export it from the aggregator, which maps port names to module functions:

**File:** `lua/sandbox/adapters/podman/containers_engine.lua`

```lua
local restart_container = require("sandbox.adapters.podman.containers.restart_container")

return {
  -- ...
  restart_container = restart_container.restart_container,
}
```

## 3. Write the use case

A thin function over the injected engine. It exists so the command layer never
names an adapter.

**File:** `lua/sandbox/core/usecases/containers/restart_container.lua`

```lua
---@module 'sandbox.core.usecases.containers.restart_container'
--- Use case: Restart a container
--- @param engine table: must implement restart_container(container_id, on_done)
--- @param container_id string
--- @param on_done? fun(ok: boolean, err: string|nil)
return function(engine, container_id, on_done)
  return engine.restart_container(container_id, on_done)
end
```

This one returns a bare function, unlike the adapter module above.

## 4. Export a handler

**File:** `lua/sandbox/bindings/usrcmds/container_commands.lua`

```lua
--- Restart a container
---@param id string
function M.restart(id)
  local engine = require("sandbox").get_engine()
  if not engine then
    return
  end

  if not id or id == "" then
    notify.warn("Usage: :Sandbox container restart <container-id>")
    return
  end

  local usecase = require("sandbox.core.usecases.containers.restart_container")
  usecase(engine, id, function(ok, err)
    if ok then
      notify.info("Container restarted successfully: " .. id)
    else
      notify.error("Failed to restart container " .. id .. ": " .. friendly_error(err), { id = id, err = err })
    end
  end)
end
```

Three things every handler in that file does, and none of them is optional:

- `get_engine()` returns `nil` and has already notified when there is no usable
  engine — bail, do not notify twice.
- `sandbox.notify`, not `vim.notify`. It carries the plugin name and routes the
  full error text to `sandbox.logger` while `max_error_length` caps what the
  popup shows.
- `sandbox.util.friendly_error` turns an engine's raw stderr into a sentence.
  A destructive action additionally wraps its work in
  `sandbox.util.confirm.destructive(prompt, fn)`, which skips the prompt when
  `opts.confirm_destructive = false`.

## 5. Add a route

You do not register a new top-level command. Everything hangs off the single
`:Sandbox`/`:Sbx` verb with its ten sub-namespaces (`container`, `image`,
`volume`, `network`, `compose`, `engine`, `registry`, `docs`, `devcontainer`,
and `wsl` where `wsl.exe` exists).

**File:** `lua/sandbox/bindings/usrcmds/init.lua`, in the matching
`*_routes()` function:

```lua
{
  path = { "container", "restart" },
  args = { { name = "id", type = "CONTAINER_ID" } },
  flags = BUFFER_FLAG,
  desc = "Restart a container (--buffer: stream to a terminal buffer)",
  run = function(ctx)
    if ctx.flags.buffer then
      container_buffer_cmds.restart(ctx.args.id)
    else
      container_cmds.restart(ctx.args.id)
    end
  end,
},
```

`type = "CONTAINER_ID"` gives `:Sandbox container restart <Tab>` live
completion against the active engine for free — likewise `IMAGE_ID`,
`VOLUME_NAME`, `NETWORK_NAME`, `DISTRO_NAME`. `flags = BUFFER_FLAG` adds
`--buffer`/`-b`; take it only if you also write the terminal-buffer variant in
`container_commands_buffer.lua`, since a flag that changes nothing is worse
than no flag.

For an option that takes a value, use `kv` rather than a positional if the rest
of the line is free-form — that is why `container exec` spells the working
directory `workdir=/app`.

## 6. Optional: a view

If the result needs a buffer rather than a notification, add a module under
`lua/sandbox/ui/`. `list_view.lua` is the pattern for a list, `inspect_view.lua`
for folded metadata, `log_follow_view.lua` for a streaming job.

## 7. Write the spec

**File:** `TESTS/sandbox/...`, mirroring the module's own path.

```lua
local fake_run_argv = require("TESTS.sandbox.helpers.fake_run_argv")
```

Note the uppercase `TESTS` — the runtime path entry is the repo root, and the
directory is spelled that way on disk. See
[`TESTS/README.md`](../TESTS/README.md).

## 8. Document it

1. Add the row to [`BINDINGS.md`](BINDINGS.md) by hand — it carries prose and
   keymap tables a route table cannot express.
2. Run `:Sandbox docs generate` to rewrite
   [`GENERATED_COMMANDS.md`](GENERATED_COMMANDS.md) from the live route table.
3. Diff the two. This is the fast "did I wire the route the way I described it"
   check — much faster than launching a fresh Neovim and tabbing through every
   level by hand.
4. If the operation is user-visible in a new way, add it to the matching page
   under [`FEATURES/`](FEATURES/README.md), and to `doc/sandbox.txt`.

---

## Where each piece lives

| File | Purpose |
|---|---|
| `core/ports/*_engine.lua` | The interface every adapter fulfils |
| `adapters/{docker,podman,nerdctl}/**/*.lua` | One file per operation, per engine |
| `adapters/<engine>/*_engine.lua` | Aggregator: port name → module function |
| `core/usecases/<kind>/*.lua` | The operation, over an injected engine |
| `bindings/usrcmds/*_commands.lua` | Exported handler: notify, confirm, error text |
| `bindings/usrcmds/init.lua` | The composer route |
| `ui/*.lua` | Optional buffer view |
| `TESTS/sandbox/**` | One spec file per module under test |

## Debugging

- `:messages` shows every notification, including the truncated ones.
- `sandbox.logger` has the untruncated error text.
- `:Sandbox engine get` says which engine a failing command actually used.
- `:checkhealth sandbox` — see [health.md](health.md).
