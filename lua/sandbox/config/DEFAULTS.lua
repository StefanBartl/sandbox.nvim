---@module 'sandbox.config.DEFAULTS'
--- Default values for sandbox.nvim' own configuration.
--- See config/init.lua for how these are merged with user-supplied options.

---@type Sandbox.Config.Options
return {
  engine = nil, -- no default here, to allow dynamic detection
  confirm_destructive = true, -- ask before remove/prune/kill; set false to skip the prompt
  default_shell = "sh", -- shell used by `container exec` when none is given
  refresh_interval = nil, -- ms between list-view auto-refreshes; nil/0 disables
  list_split = "left", -- window placement for list views
  list_size = nil, -- width/height of list view splits; nil uses Neovim's default
  progress_style = "auto", -- indicator while pull/push/build run; needs lib.nvim, no-op without it
  menu = {
    -- Right-click context menu on list-view buffers (nvzone/menu, soft
    -- dependency; entries provided by sandbox.integrations.menu). Off
    -- automatically when nvzone/menu isn't installed -- this only gates
    -- whether the trigger and entries are offered at all.
    enable = true,
  },
}
