---@module 'sandbox.ui.list_view'
--- Display a list of containers in a vertical split buffer, with
--- buffer-local keymaps to act on the container under the cursor
--- (see `?` inside the buffer, or docs/BINDINGS.md).

local notify = require("sandbox.notify")
local list_actions = require("sandbox.ui.list_actions")
local highlights = require("sandbox.ui.highlights")

local status_ns = vim.api.nvim_create_namespace("sandbox_container_status")

---@param containers table[]  the containers to display
---@param all table[]|nil  the unfiltered set, so a second filter widens from
---       the original rather than compounding onto the first
return function(containers, all)
  if type(containers) ~= "table" then
    notify.error("Invalid container list: not a table")
    return
  end
  all = all or containers

  local lines = {}
  for _, container in ipairs(containers) do
    table.insert(
      lines,
      string.format(
        "[%s] %s (%s)",
        container.status or "unknown",
        container.name or "<no name>",
        container.id and container.id:sub(1, 12) or "<no id>"
      )
    )
  end

  local list_opts = require("sandbox.config").options
  local bufnr = require("lib.nvim.window").open_named_scratch(
    "sandbox.nvim://container-list",
    lines,
    { filetype = "log", split = list_opts.list_split, size = list_opts.list_size }
  )

  highlights.ensure_defined()
  vim.api.nvim_buf_clear_namespace(bufnr, status_ns, 0, -1)
  for i, container in ipairs(containers) do
    local status_text = container.status or "unknown"
    vim.hl.range(bufnr, status_ns, highlights.group_for_status(status_text), { i - 1, 0 }, { i - 1, #status_text + 2 })
  end

  local container_cmds = require("sandbox.bindings.usrcmds.container_commands")
  ---@param c table
  local function ref(c)
    return c.id or c.name
  end

  list_actions.set_keymaps(
    bufnr,
    {
      {
        lhs = "<CR>",
        desc = "inspect",
        fn = function(c)
          container_cmds.inspect(ref(c))
        end,
      },
      {
        lhs = "i",
        desc = "inspect",
        fn = function(c)
          container_cmds.inspect(ref(c))
        end,
      },
      {
        lhs = "s",
        desc = "start",
        fn = function(c)
          container_cmds.start(ref(c))
        end,
      },
      {
        lhs = "x",
        desc = "stop",
        fn = function(c)
          container_cmds.stop(ref(c))
        end,
      },
      {
        lhs = "X",
        desc = "kill",
        fn = function(c)
          container_cmds.kill(ref(c))
        end,
      },
      {
        lhs = "r",
        desc = "restart",
        fn = function(c)
          container_cmds.restart(ref(c))
        end,
      },
      {
        lhs = "p",
        desc = "pause",
        fn = function(c)
          container_cmds.pause(ref(c))
        end,
      },
      {
        lhs = "P",
        desc = "unpause",
        fn = function(c)
          container_cmds.unpause(ref(c))
        end,
      },
      {
        lhs = "n",
        desc = "rename",
        fn = function(c)
          require("lib.nvim.ui.kit").input({
            title = "New name for " .. (c.name or c.id) .. ": ",
            on_submit = function(new_name)
              if new_name and new_name ~= "" then
                container_cmds.rename(ref(c), new_name)
              end
            end,
          })
        end,
      },
      {
        lhs = "D",
        desc = "remove",
        fn = function(c)
          container_cmds.remove(ref(c))
        end,
      },
      {
        lhs = "l",
        desc = "logs",
        fn = function(c)
          container_cmds.logs(ref(c))
        end,
      },
      {
        lhs = "L",
        desc = "logs (follow)",
        fn = function(c)
          container_cmds.logs_follow(ref(c))
        end,
      },
      {
        lhs = "e",
        desc = "exec",
        fn = function(c)
          container_cmds.exec(ref(c))
        end,
      },
      {
        lhs = "t",
        desc = "top",
        fn = function(c)
          container_cmds.top(ref(c))
        end,
      },
      {
        lhs = "T",
        desc = "stats",
        fn = function(c)
          container_cmds.stats(ref(c))
        end,
      },
      {
        lhs = "R",
        desc = "refresh list",
        no_item = true,
        fn = function()
          container_cmds.list()
        end,
      },
    },
    containers,
    0,
    {
      surface = "containers",
      -- Re-render after an engine switch: the list belongs to the engine that
      -- produced it, so leaving stale rows on screen after switching would be
      -- worse than not offering the key at all.
      refresh = function()
        container_cmds.list()
      end,
      -- Narrow across every field of a container (name, id, status, image),
      -- not just the rendered line -- `/` already searches the text. Filtering
      -- always starts from `all`, so a second filter widens instead of
      -- compounding, and an empty query restores the full list.
      filter = function(query)
        if query == "" then
          return require("sandbox.ui.list_view")(all, all)
        end
        local q = query:lower()
        local kept = {}
        for _, c in ipairs(all) do
          for _, field in ipairs({ c.name, c.id, c.status, c.image }) do
            if type(field) == "string" and field:lower():find(q, 1, true) then
              kept[#kept + 1] = c
              break
            end
          end
        end
        if #kept == 0 then
          notify.warn(("No container matching %q"):format(query))
          return
        end
        require("sandbox.ui.list_view")(kept, all)
      end,
    }
  )

  list_actions.set_visual_bulk_actions(bufnr, {
    {
      lhs = "s",
      desc = "start selection",
      fn = function(items)
        for _, c in ipairs(items) do
          container_cmds.start(ref(c))
        end
      end,
    },
    {
      lhs = "x",
      desc = "stop selection",
      fn = function(items)
        for _, c in ipairs(items) do
          container_cmds.stop(ref(c))
        end
      end,
    },
    {
      lhs = "X",
      desc = "kill selection",
      fn = function(items)
        list_actions.bulk_confirm_then("Kill", "container", items, ref, container_cmds.kill)
      end,
    },
    {
      lhs = "D",
      desc = "remove selection",
      fn = function(items)
        list_actions.bulk_confirm_then("Remove", "container", items, ref, container_cmds.remove)
      end,
    },
  }, containers, 0, "containers")

  list_actions.setup_autorefresh(bufnr, container_cmds.list)
end
