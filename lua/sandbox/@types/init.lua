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
---@field progress_style "auto"|"notify"|"statusline"|"fidget"|"float"|"kit"|nil
--- indicator for long-running argv (pull/push/build); needs lib.nvim, no-op without it (default "auto")

---@class Sandbox.RunOpts
---@field image string
---@field name? string
---@field ports? string[] "host:container" mappings
---@field volumes? string[] "host:container" mount specs
---@field env? string[] "KEY=VALUE" entries
---@field command? string[] overrides the image's default CMD/entrypoint args
