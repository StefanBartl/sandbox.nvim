---@module 'sandbox.@types'
--- Shared type annotations for sandbox.nvim.

---@alias Sandbox.Engine "podman"|"docker"

---@class Sandbox.Config.Options
---@field engine Sandbox.Engine|nil
---@field confirm_destructive boolean|nil ask before remove/prune/kill (default true)

---@class Sandbox.RunOpts
---@field image string
---@field name? string
---@field ports? string[] "host:container" mappings
---@field volumes? string[] "host:container" mount specs
---@field env? string[] "KEY=VALUE" entries
