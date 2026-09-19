---@module 'sandbox.config'
--- Configuration for the plugin

local M = {}

---@type Sandbox.Config.Options
local defaults = require("sandbox.config.DEFAULTS")

---@type Sandbox.Config.Options
M.options = vim.deepcopy(defaults)

---@internal
--- ERR-50: keys `setup()` accepts, hand-authored from @types/init.lua's
--- `Sandbox.Config.Options`/`Sandbox.MenuOptions` annotations -- deliberately
--- NOT derived from `pairs(DEFAULTS)`. Several real keys here
--- (`engine`, `refresh_interval`, `list_size`, `keymaps`) default to `nil`,
--- and a Lua table literal never creates a key for a `nil`-valued field, so
--- `pairs(DEFAULTS)` would never see them; a naive `DEFAULTS[key] ~= nil`
--- membership check would then misreport every one of them as unknown the
--- moment a user actually set it, which is worse than not validating at all.
---
--- `true` means "a leaf, don't recurse further". `menu` is the one
--- fixed-schema sub-table. `keymaps` is left a leaf even though it is itself
--- a table (`Sandbox.Keymaps`): its sub-keys are per-list-kind
--- (`containers`, `images`, ...) and, within those, arbitrary action names
--- that `lib.nvim.bindings.keymap`'s registry already validates and reports
--- on its own (see @types/init.lua's `Sandbox.Keymaps` doc comment) --
--- checking them again here would duplicate that against a schema that has
--- to be kept in sync with every list view's own action names.
---@type table<string, true|table<string, true>>
local KNOWN = {
  engine = true,
  confirm_destructive = true,
  default_shell = true,
  refresh_interval = true,
  list_split = true,
  list_size = true,
  progress_style = true,
  hover = true,
  max_error_length = true,
  status_cache_ttl_ms = true,
  completion_cache_ttl_ms = true,
  keymaps = true,
  menu = { enable = true },
}

---@internal
--- `key` with the nearest known one as a hint when there is a plausible one
--- (edit distance <= 3) -- same pattern as cascade.nvim/spotlight.nvim/
--- buffer-ctx.nvim's config modules.
---@param key any
---@param known table<string, any>
---@param prefix string
---@return string
local function describe_unknown(key, known, prefix)
  local levenshtein = require("lib.lua.strings.distance").levenshtein
  local name = tostring(key)
  local best, best_distance = nil, nil
  for candidate in pairs(known) do
    local d = levenshtein(name, candidate)
    if d <= 3 and (best_distance == nil or d < best_distance) then
      best, best_distance = candidate, d
    end
  end
  if best then
    return ("unknown option '%s%s' (did you mean '%s%s'?)"):format(prefix, name, prefix, best)
  end
  return ("unknown option '%s%s'"):format(prefix, name)
end

---@internal
--- Walk `user_tbl` against `known` (a `KNOWN` subtree), appending to `issues`
--- in place, and return what may safely be merged. `prefix` is the dotted
--- path so far (`""` at the root, `"menu."`), which is what turns a bare
--- sub-key name into a full path once nested a level in. A non-table value
--- where `known` names a fixed-schema table (`menu = 5`) is rejected the
--- same way instead of reaching the merge, where it would replace the whole
--- section wholesale and throw on the first nested read.
---@param user_tbl table
---@param known table<string, true|table>
---@param prefix string
---@param issues string[]
---@return table clean
local function sanitize_level(user_tbl, known, prefix, issues)
  local clean = {}
  for key, value in pairs(user_tbl) do
    local known_entry = known[key]
    if known_entry == nil then
      issues[#issues + 1] = describe_unknown(key, known, prefix)
    elseif type(known_entry) == "table" then
      if type(value) ~= "table" then
        issues[#issues + 1] = ("option '%s%s' must be a table, got %s -- using the default"):format(
          prefix,
          key,
          type(value)
        )
      else
        local nested = sanitize_level(value, known_entry, prefix .. key .. ".", issues)
        -- Only set the key at all when a real override survived: an empty
        -- table would otherwise still deep-merge as a no-op here, but
        -- leaving it out entirely keeps a fully-rejected section (every
        -- sub-key typo'd) from looking any different than the caller simply
        -- not mentioning it.
        if next(nested) ~= nil then
          clean[key] = nested
        end
      end
    else
      clean[key] = value
    end
  end
  return clean
end

---@internal
--- Drop what cannot be merged, and say so, before the merge (ERR-50): an
--- unknown key (`lits_size`, `menu = { enalbe = ... }`) previously landed in
--- `M.options` as an inert extra field -- `vim.tbl_deep_extend` does not
--- check its own input -- while the option the user actually meant to set
--- silently kept its default, with nothing anywhere saying so.
---@param user_opts table
---@return table clean
---@return string[] issues
local function sanitize(user_opts)
  local issues = {}
  local clean = sanitize_level(user_opts, KNOWN, "", issues)
  table.sort(issues)
  return clean, issues
end

--- What the last `setup()` call had to reject: one human-readable line per
--- unknown key, dropped before the merge rather than silently kept as a dead
--- field. Read by `:checkhealth` (`sandbox.health`), the same way as the
--- refresh_interval/list_size value-degradation warnings there.
---@type string[]
M.issues = {}

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
---
--- Merges into a fresh copy of the defaults, not into the live `M.options` --
--- otherwise a second call accumulates onto whatever the first call already
--- wrote, including the auto-detected `engine` below. That corrupts
--- `engine_named`: the second call would see `options.engine` already
--- filled in from the *first* call's detection and record it as named, even
--- though this call's own `opts` never named one.
--- @param opts Sandbox.Config.Options|nil: Optional user configuration
function M.setup(opts)
  local clean, issues = sanitize(type(opts) == "table" and opts or {})
  M.issues = issues
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(defaults), clean)
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
