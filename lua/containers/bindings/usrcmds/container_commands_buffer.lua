---@module 'containers.bindings.usrcmds.container_commands_buffer'
---@brief Terminal-buffer variants of container/image operations.
---@description
--- These open a new terminal buffer and stream the CLI output directly into
--- it, instead of swallowing stdout/stderr into vim.notify. Useful for
--- commands with verbose output (start, stop, prune) or for workflows where
--- the user wants a persistent, scrollable output pane.
---
--- Exported as plain functions (M.start/M.stop/M.kill/M.remove/M.prune/
--- M.pull/M.image_prune), called from :Container/:Image's composer routes
--- when the route's `--buffer`/`-b` flag is set, instead of registering
--- separate `*Buffer` commands (ContainerStartBuffer, etc. pre-migration).
--- Each function's own body is unchanged; only how it gets invoked moved.

local M = {}

local function open_term_buffer(name, cmd)
  -- Reuse an existing buffer with the same name if still valid
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_name(buf) == name then
      vim.api.nvim_buf_delete(buf, { force = true })
      break
    end
  end

  vim.cmd("vnew")
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_name(buf, name)
  vim.fn.termopen(cmd)
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_set_current_buf(buf)
  -- Enter terminal insert mode so output is visible immediately
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("i", true, false, true), "n", true)
end

---@return string|nil engine_name, string|nil err
local function require_engine()
  local engine_name = require("containers.config").options.engine
  if not engine_name then
    vim.notify("[nvim-containers] No engine configured", vim.log.levels.ERROR)
    return nil
  end
  return engine_name
end

--- Start a container, streaming output into a terminal buffer
---@param id string
function M.start(id)
  local engine_name = require_engine()
  if not engine_name then
    return
  end
  if not id or id == "" then
    vim.notify("Usage: :Container start <container-id> --buffer", vim.log.levels.WARN)
    return
  end
  open_term_buffer("nvim-containers://term/start/" .. id, { engine_name, "start", id })
end

--- Stop a container, streaming output into a terminal buffer
---@param id string
function M.stop(id)
  local engine_name = require_engine()
  if not engine_name then
    return
  end
  if not id or id == "" then
    vim.notify("Usage: :Container stop <container-id> --buffer", vim.log.levels.WARN)
    return
  end
  open_term_buffer("nvim-containers://term/stop/" .. id, { engine_name, "stop", "--time=1", id })
end

--- Kill a container, streaming output into a terminal buffer
---@param id string
function M.kill(id)
  local engine_name = require_engine()
  if not engine_name then
    return
  end
  if not id or id == "" then
    vim.notify("Usage: :Container kill <container-id> --buffer", vim.log.levels.WARN)
    return
  end
  open_term_buffer("nvim-containers://term/kill/" .. id, { engine_name, "kill", id })
end

--- Remove a container, streaming output into a terminal buffer
---@param id string
function M.remove(id)
  local engine_name = require_engine()
  if not engine_name then
    return
  end
  if not id or id == "" then
    vim.notify("Usage: :Container remove <container-id> --buffer", vim.log.levels.WARN)
    return
  end
  open_term_buffer("nvim-containers://term/remove/" .. id, { engine_name, "rm", id })
end

--- Prune all stopped containers, streaming output into a terminal buffer
function M.prune()
  local engine_name = require_engine()
  if not engine_name then
    return
  end
  open_term_buffer("nvim-containers://term/prune", { engine_name, "container", "prune", "-f" })
end

--- Pull an image, streaming output into a terminal buffer
---@param name string
function M.pull(name)
  local engine_name = require_engine()
  if not engine_name then
    return
  end
  if not name or name == "" then
    vim.notify("Usage: :Image pull <image-name> --buffer", vim.log.levels.WARN)
    return
  end
  open_term_buffer("nvim-containers://term/pull/" .. name, { engine_name, "pull", name })
end

--- Prune dangling images, streaming output into a terminal buffer
function M.image_prune()
  local engine_name = require_engine()
  if not engine_name then
    return
  end
  open_term_buffer("nvim-containers://term/image-prune", { engine_name, "image", "prune", "-f" })
end

return M
