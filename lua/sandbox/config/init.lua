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
--- `options.engine` is filled in by the detection below.
---@type boolean
M.engine_named = false

--- What the last `setup()` call had to reject: one human-readable line per
--- unknown key or wrong-typed value, dropped before the merge rather than
--- silently kept as a dead field. Read by `:checkhealth` (`sandbox.health`),
--- the same way as the refresh_interval/list_size value-degradation warnings there.
---@type string[]
M.issues = {}

---@type Lib.Config.Instance
local cfg
cfg = require("lib.lua.config").new(defaults, {
  name = "sandbox",
  -- Real keys that default to nil (a table literal never creates a key for a
  -- nil-valued field), so the schema inferred from DEFAULTS cannot know them.
  optional = {
    engine = "string",
    refresh_interval = "number",
    list_size = "number",
    keymaps = "table|false",
  },
  resolve = function(current)
    M.engine_named = current.engine ~= nil

    -- If no engine is explicitly set, detect automatically.
    --
    -- Deliberately the cheap detection (`PATH` only): `setup` runs at startup,
    -- and asking each installed engine whether it answers costs ~385 ms apiece
    -- for a question nothing has asked yet. `resolve_engine_name` does that
    -- part, lazily, at a site that is about to use the engine.
    if not current.engine then
      current.engine = require("sandbox.engine_utils").get_engine()
    end
  end,
  on_change = function(current)
    M.options = current
    M.issues = cfg.issues()
  end,
})

--- Setup configuration with user options
---
--- Every call starts from a fresh copy of the defaults, not from the live
--- `M.options`: a second call must not accumulate onto what the first one
--- wrote, including the auto-detected `engine`, or `engine_named` would record
--- that detection as the user's choice.
--- @param opts Sandbox.Config.Options|nil: Optional user configuration
function M.setup(opts)
  cfg.setup(type(opts) == "table" and opts or nil)
end

return M
