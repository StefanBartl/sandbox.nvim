---@module 'plugin.container_commands_buffer'
---@brief Terminal-buffer variants of container commands.
---@description
--- These commands open a new terminal buffer and stream the CLI output directly
--- into it, instead of swallowing stdout/stderr into vim.notify.
--- Useful for commands with verbose output (start, stop, prune) or for
--- workflows where the user wants a persistent, scrollable output pane.

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

--- Start a container and stream output into a terminal buffer
--- Usage: :ContainerStartBuffer <container-id>
vim.api.nvim_create_user_command("ContainerStartBuffer", function(opts)
  local engine_name = require("containers.config").options.engine
  if not engine_name then
    vim.notify("[nvim-containers] No engine configured", vim.log.levels.ERROR)
    return
  end

  local id = opts.args
  if not id or id == "" then
    vim.notify("Usage: :ContainerStartBuffer <container-id>", vim.log.levels.WARN)
    return
  end

  open_term_buffer(
    "nvim-containers://term/start/" .. id,
    { engine_name, "start", id }
  )
end, { nargs = 1 })

--- Stop a container and stream output into a terminal buffer
--- Usage: :ContainerStopBuffer <container-id>
vim.api.nvim_create_user_command("ContainerStopBuffer", function(opts)
  local engine_name = require("containers.config").options.engine
  if not engine_name then
    vim.notify("[nvim-containers] No engine configured", vim.log.levels.ERROR)
    return
  end

  local id = opts.args
  if not id or id == "" then
    vim.notify("Usage: :ContainerStopBuffer <container-id>", vim.log.levels.WARN)
    return
  end

  open_term_buffer(
    "nvim-containers://term/stop/" .. id,
    { engine_name, "stop", "--time=1", id }
  )
end, { nargs = 1 })

--- Kill a container and stream output into a terminal buffer
--- Usage: :ContainerKillBuffer <container-id>
vim.api.nvim_create_user_command("ContainerKillBuffer", function(opts)
  local engine_name = require("containers.config").options.engine
  if not engine_name then
    vim.notify("[nvim-containers] No engine configured", vim.log.levels.ERROR)
    return
  end

  local id = opts.args
  if not id or id == "" then
    vim.notify("Usage: :ContainerKillBuffer <container-id>", vim.log.levels.WARN)
    return
  end

  open_term_buffer(
    "nvim-containers://term/kill/" .. id,
    { engine_name, "kill", id }
  )
end, { nargs = 1 })

--- Remove a container and stream output into a terminal buffer
--- Usage: :ContainerRemoveBuffer <container-id>
vim.api.nvim_create_user_command("ContainerRemoveBuffer", function(opts)
  local engine_name = require("containers.config").options.engine
  if not engine_name then
    vim.notify("[nvim-containers] No engine configured", vim.log.levels.ERROR)
    return
  end

  local id = opts.args
  if not id or id == "" then
    vim.notify("Usage: :ContainerRemoveBuffer <container-id>", vim.log.levels.WARN)
    return
  end

  open_term_buffer(
    "nvim-containers://term/remove/" .. id,
    { engine_name, "rm", id }
  )
end, { nargs = 1 })

--- Prune all stopped containers and stream output into a terminal buffer
vim.api.nvim_create_user_command("ContainerPruneBuffer", function()
  local engine_name = require("containers.config").options.engine
  if not engine_name then
    vim.notify("[nvim-containers] No engine configured", vim.log.levels.ERROR)
    return
  end

  open_term_buffer(
    "nvim-containers://term/prune",
    { engine_name, "container", "prune", "-f" }
  )
end, {})

--- Pull an image and stream output into a terminal buffer
--- Usage: :ImagePullBuffer <image-name>
vim.api.nvim_create_user_command("ImagePullBuffer", function(opts)
  local engine_name = require("containers.config").options.engine
  if not engine_name then
    vim.notify("[nvim-containers] No engine configured", vim.log.levels.ERROR)
    return
  end

  local name = opts.args
  if not name or name == "" then
    vim.notify("Usage: :ImagePullBuffer <image-name>", vim.log.levels.WARN)
    return
  end

  open_term_buffer(
    "nvim-containers://term/pull/" .. name,
    { engine_name, "pull", name }
  )
end, { nargs = 1 })

--- Prune dangling images and stream output into a terminal buffer
vim.api.nvim_create_user_command("ImagePruneBuffer", function()
  local engine_name = require("containers.config").options.engine
  if not engine_name then
    vim.notify("[nvim-containers] No engine configured", vim.log.levels.ERROR)
    return
  end

  open_term_buffer(
    "nvim-containers://term/image-prune",
    { engine_name, "image", "prune", "-f" }
  )
end, {})
