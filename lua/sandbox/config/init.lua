-- Configuration for the plugin

local M = {}

---@type Sandbox.Config.Options
local defaults = require("sandbox.config.DEFAULTS")

---@type Sandbox.Config.Options
M.options = vim.deepcopy(defaults)

--- Setup configuration with user options
--- @param opts Sandbox.Config.Options|nil: Optional user configuration
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.options, opts or {})

  -- If no engine is explicitly set, detect automatically
  if not M.options.engine then
    M.options.engine = require("sandbox.engine_utils").get_engine()
  end
end

return M
