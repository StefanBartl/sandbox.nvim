---@module 'sandbox.@types'
--- Shared type annotations for sandbox.nvim.

---@alias Sandbox.Engine "podman"|"docker"|"nerdctl"

---@class Sandbox.Config.Options
---@field engine Sandbox.Engine|nil
---@field confirm_destructive boolean|nil ask before remove/prune/kill (default true)
---@field default_shell string|nil shell used by `container exec` when none is given (default "sh")
---@field refresh_interval integer|nil ms between auto-refreshes of list views; nil/0 disables (default nil)
---@field list_split "above"|"below"|"left"|"right"|nil window placement for list views (default "left")
---@field list_size integer|nil width/height of list view splits; nil uses Neovim's default

---@class Sandbox.RunOpts
---@field image string
---@field name? string
---@field ports? string[] "host:container" mappings
---@field volumes? string[] "host:container" mount specs
---@field env? string[] "KEY=VALUE" entries
