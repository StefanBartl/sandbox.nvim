---@module 'sandbox.telescope.picker'
--- Shared telescope.nvim picker builder for the sandbox extension. Mirrors
--- sandbox.ui.list_actions' keymap shape (`{ lhs, desc, fn }`) so acting on
--- a container/image/WSL distro from a fuzzy picker stays consistent with
--- the buffer-local keymaps in the list views -- this is meant as an
--- alternative front-end to those, not a separate command surface.
---
--- telescope.nvim is an optional dependency: nothing under
--- lua/sandbox/telescope/ or lua/telescope/_extensions/sandbox.lua is
--- required by the plugin's own setup() path, only pulled in if/when the
--- user calls `require("telescope").load_extension("sandbox")`.

local M = {}

---@class Sandbox.TelescopePicker.Key
---@field lhs string keymap for `attach_mappings` (index 1 is bound as the default <CR> action too)
---@field desc string
---@field fn fun(item: table)

---@class Sandbox.TelescopePicker.Entry
---@field display string
---@field ordinal string

---@class Sandbox.TelescopePicker.Opts
---@field title string
---@field items table[]
---@field entry fun(item: table): Sandbox.TelescopePicker.Entry
---@field keys Sandbox.TelescopePicker.Key[]

---@param opts Sandbox.TelescopePicker.Opts
function M.build(opts)
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  pickers
    .new({}, {
      prompt_title = opts.title,
      finder = finders.new_table({
        results = opts.items,
        entry_maker = function(item)
          local e = opts.entry(item)
          return { value = item, display = e.display, ordinal = e.ordinal }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection and opts.keys[1] then
            opts.keys[1].fn(selection.value)
          end
        end)

        for i = 2, #opts.keys do
          local key = opts.keys[i]
          map({ "i", "n" }, key.lhs, function()
            local selection = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            if selection then
              key.fn(selection.value)
            end
          end)
        end

        return true
      end,
    })
    :find()
end

return M
