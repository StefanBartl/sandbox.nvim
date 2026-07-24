-- Default values for sandbox.nvim' own configuration.
-- See config/init.lua for how these are merged with user-supplied options.

---@type Sandbox.Config.Options
return {
  engine = nil, -- no default here, to allow dynamic detection
  confirm_destructive = true, -- ask before remove/prune/kill; set false to skip the prompt
}
