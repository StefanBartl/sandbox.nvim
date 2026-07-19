# Adding a New Use Case to `nvim-containers`

This guide explains how to add a new functionality ("use case") to the `nvim-containers` plugin following its hexagonal architecture design.

---

## 1. Define the Purpose

Clearly describe what the new use case should do.

> Examples:
> - Show logs of a container
> - Start or stop a container
> - Execute a command inside a container

---

## 2. Declare the Interface (Port)

Update the core interface `ContainerEngine` with a new method.

**File:** `lua/containers/core/ports/container_engine.lua`

```lua
restart_container = function(id)
  error(id .. ": restart_container not implemented")
end
```

> Use `_` prefix to avoid "unused variable" warnings if needed.

---

## 3. Implement the Adapter (e.g. for Podman)

Add the logic for the method in the corresponding adapter module.

**File:** `lua/containers/adapters/podman/containers/restart.lua`

```lua
return function(id)
  local output = vim.fn.system({ "podman", "restart", id })
  if vim.v.shell_error ~= 0 then
    return false, "Podman restart failed: " .. output
  end
  return true
end
```

Make sure it’s exported in the aggregator:

**File:** `adapters/podman/container_engine.lua`

```lua
restart_container = require("containers.adapters.podman.containers.restart"),
```

---

## 4. Create the Use Case

Encapsulate the action in a reusable function.

**File:** `lua/containers/core/usecases/containers/restart_container.lua`

```lua
--- Restart a container via the injected engine
--- @param engine table
--- @param container_id string
return function(engine, container_id)
  return engine.restart_container(container_id)
end
```

---

## 5. Register a Neovim Command

Commands are built via [`lib.nvim.usercmd.composer`](https://github.com/StefanBartl/lib.nvim)
as subcommands of the existing `:Container`/`:Image`/`:Wsl` verbs — you do
not register a new top-level command for a new use case, you add a route.

First, export a plain handler function from the relevant commands module.

**File:** `lua/containers/bindings/usrcmds/container_commands.lua`

```lua
--- Restart a container
---@param id string
function M.restart(id)
  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.containers.restart_container")

  local ok, result = pcall(usecase, engine, id)
  if not ok then
    vim.notify("Restart failed: " .. result, vim.log.levels.ERROR)
  else
    vim.notify("Container restarted: " .. id)
  end
end
```

Then add a route for it in the `:Container` verb's route table.

**File:** `lua/containers/bindings/usrcmds/init.lua`

```lua
{ path = { "restart" },
  args = { { name = "id", type = "CONTAINER_ID" } },
  desc = "Restart a container",
  run = function(ctx) container_cmds.restart(ctx.args.id) end },
```

The `CONTAINER_ID` arg type gives `:Container restart <Tab>` live
completion against the active engine for free — no extra work needed. Now
`:Container restart <id>` works, plus `<Tab>` completion and the entry in
`composer.document()`'s auto-generated docs (if wired up).

---

## 6. (Optional) Add a View

If output needs to be shown in a buffer, create a view module.

**Example:** `lua/containers/ui/log_view.lua`

---

## 7. Plugin Declaration (lazy.nvim)

New subcommands don't need a new entry in `cmd = {...}` — they live under
the existing `:Container` verb.

```lua
{
  "StefanBartl/nvim-containers.nvim",
  dependencies = { "StefanBartl/lib.nvim" },
  cmd = { "Container", "Image", "Wsl" },
  config = function()
    require("containers").setup({
      engine = "podman",
    })
  end,
}
```

---

## 8. File Organization

| Folder | Content |
|--------|---------|
| `core/usecases/containers/` | container-related logic |
| `core/usecases/images/`     | image-related logic     |
| `adapters/podman/containers/` | container command implementations |
| `adapters/podman/images/`     | image command implementations |

---

## 9. Debugging Tips

- `:messages` shows all notifications
- Use `vim.inspect(tbl)` to log tables
- Check `vim.v.shell_error` after CLI calls

---

## 10. Future Use Case Ideas

- Container stats
- Image tagging
- Save/load images
- Volume & network management

---

## Summary

| File | Purpose |
|------|---------|
| `core/ports/container_engine.lua` | Define the interface |
| `core/usecases/containers/*.lua`  | Use case logic        |
| `adapters/podman/containers/*.lua`| Podman implementation |
| `bindings/usrcmds/container_commands.lua` | Exported handler function |
| `bindings/usrcmds/init.lua`       | Composer route (`:Container <subcommand>`) |
| `ui/*.lua`                        | Optional buffer view  |

---
