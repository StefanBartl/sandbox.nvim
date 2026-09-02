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
  progress_style = "auto",
  -- Register a position preview with hover.nvim, so `:Hover show` on an image
  -- reference in a Dockerfile or a compose file says whether it is pulled,
  -- how big it is, and what is running from it.
  --
  -- Never on the automatic trigger: an engine start costs 230-490 ms
  -- measured, so the contribution is registered as `on_request`. Without a
  -- hover.nvim that honours that flag, nothing is registered at all -- see
  -- docs/hover.md. A no-op without hover.nvim installed.
  hover = true,
  -- How long a statusline reading and a completion listing stay cached, in
  -- ms. Both trade freshness against how often the engine is asked; raise
  -- them for a slow daemon, lower them if a stale reading annoys you.
  -- How much of an unrecognized adapter error survives into the
  -- notification. The full text always goes to sandbox.logger; this only
  -- caps the popup.
  max_error_length = 200,
  status_cache_ttl_ms = 3000,
  completion_cache_ttl_ms = 4000, -- indicator while pull/push/build run; needs lib.nvim, no-op without it
  -- List-view keymaps. `false` binds none; a table overrides individual
  -- actions per list kind (see Sandbox.Keymaps). Every key keeps its default
  -- unless named here.
  keymaps = nil,
  menu = {
    -- Right-click context menu on list-view buffers (nvzone/menu, soft
    -- dependency; entries provided by sandbox.integrations.menu). Off
    -- automatically when nvzone/menu isn't installed -- this only gates
    -- whether the trigger and entries are offered at all.
    enable = true,
  },
}
