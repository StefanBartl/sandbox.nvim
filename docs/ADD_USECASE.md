# Adding a New Use Case to `nvim-containers`

This guide explains how to add a new functionality ("use case") to the `nvim-containers` plugin following its hexagonal architecture design.

---

## 1. Define the Purpose

Clearly describe what the new use case should do:

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

> Use `_` to prevent "unused variable" warnings if needed.

---

## 3. Implement the Adapter (e.g. for Podman)

Add the actual logic for the method in the selected adapter.

**File:** `lua/containers/adapters/podman/container_engine.lua`

```lua
function M.restart_container(container_id)
  local output = vim.fn.system({ "podman", "restart", container_id })
  if vim.v.shell_error ~= 0 then
    return false, "Podman restart failed: " .. output
  end
  return true
end
```

---

## 4. Create the Use Case

Encapsulate the action in a function that only depends on the interface, not the implementation.

**File:** `lua/containers/core/usecases/restart_container.lua`

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

Expose the functionality via a `:Command` that uses the use case and active engine.

**File:** `plugin/containers.lua`

```lua
vim.api.nvim_create_user_command("ContainerRestart", function(opts)
  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.restart_container")
  local id = opts.args

  local ok, result = pcall(usecase, engine, id)
  if not ok then
    vim.notify("Restart failed: " .. result, vim.log.levels.ERROR)
  else
    vim.notify("Container restarted: " .. id)
  end
end, { nargs = 1 })
```

---

## 6. (Optional) Add a View

If your use case outputs data (like logs), create a UI module.

**Example:** `lua/containers/ui/log_view.lua`

```lua
return function(lines, container_id)
  vim.cmd("vnew")
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_name(buf, "nvim-containers://logs/" .. container_id)
  vim.bo[buf].filetype = "log"
end
```

---

## 7. Update Plugin Declaration

In your Neovim plugin setup (e.g. lazy.nvim):

```vim
{
  "lavalue/nvim-containers",
  cmd = { "ContainerList", "ContainerRestart" }, -- important!
  config = function()
    require("containers").setup({
      engine = "podman",
    })
  end,
}
```

## 8. Test Your Use Case

Use `:Lazy reload`, restart Neovim, or run:

```vim
:ContainerRestart <container-id>
```

Check for correctness and error handling.

---

## Summary of File Touchpoints

| File | Purpose |
|------|---------|
| `core/ports/container_engine.lua` | Define the interface |
| `core/usecases/<name>.lua` | Declare use case |
| `adapters/<engine>/container_engine.lua` | Implement method |
| `plugin/containers.lua` | Register Neovim command |
| `ui/<optional>.lua` | Show data in a buffer |

---

## Example: exec_in_container

- Use case file: `core/usecases/exec_in_container.lua`
- Calls: `engine.exec_in_container(id, {"sh"})`
- Port method: `exec_in_container(id: string, command: string[])`
- Adapter (e.g. podman): spawns interactive shell using `vim.fn.termopen(...)`
- Command: `:ContainerExec <id> [shell]`

---

## Naming Convention

- Use `ContainerX` for Neovim commands: `:ContainerStart`, `:ContainerLogs`, ...
- Use `snake_case` for file/module names: `start_container.lua`
- Use `_id`, `_command` for unused arguments in placeholder functions

---

## Need Help?

Feel free to open an issue or discussion on Codeberg if you're unsure how to implement a new use case. Welcome, contributors!
