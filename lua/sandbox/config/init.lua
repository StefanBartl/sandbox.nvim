---@module 'sandbox.config'
--- Configuration for the plugin

local M = {}

---@type Sandbox.Config.Options
local defaults = require("sandbox.config.DEFAULTS")

---@type Sandbox.Config.Options
M.options = vim.deepcopy(defaults)

--- Whether the user named the engine, rather than it being detected.
---
--- Read by `sandbox.resolve_engine_name`, and the whole reason it is recorded:
--- a *named* engine is an instruction and is never second-guessed, while a
--- *detected* one is a guess that may be wrong and is worth checking against
--- reality. Without this flag the two are indistinguishable the moment
--- `options.engine` is filled in below.
---@type boolean
M.engine_named = false

--- Setup configuration with user options
--- @param opts Sandbox.Config.Options|nil: Optional user configuration
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.options, opts or {})
  M.engine_named = M.options.engine ~= nil

  -- If no engine is explicitly set, detect automatically.
  --
  -- Deliberately the cheap detection (`PATH` only): `setup` runs at startup,
  -- and asking each installed engine whether it answers costs ~385 ms apiece
  -- for a question nothing has asked yet. `resolve_engine_name` does that
  -- part, lazily, at a site that is about to use the engine.
  if not M.options.engine then
    M.options.engine = require("sandbox.engine_utils").get_engine()
  end
end

return M
