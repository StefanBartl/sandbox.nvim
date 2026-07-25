-- Default values for sandbox.nvim' own configuration.
-- See config/init.lua for how these are merged with user-supplied options.

---@type Sandbox.Config.Options
return {
  engine = nil, -- no default here, to allow dynamic detection
  confirm_destructive = true, -- ask before remove/prune/kill; set false to skip the prompt
  default_shell = "sh", -- shell used by `container exec` when none is given
  refresh_interval = nil, -- ms between list-view auto-refreshes; nil/0 disables
  list_split = "left", -- window placement for list views
  list_size = nil, -- width/height of list view splits; nil uses Neovim's default
}
