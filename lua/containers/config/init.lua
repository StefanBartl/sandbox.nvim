-- Configuration for the plugin

local M = {}

---@type Containers.Config.Options
local defaults = require("containers.config.DEFAULTS")

---@type Containers.Config.Options
M.options = vim.deepcopy(defaults)

--- Setup configuration with user options
--- @param opts Containers.Config.Options|nil: Optional user configuration
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.options, opts or {})

  -- If no engine is explicitly set, detect automatically
  if not M.options.engine then
    M.options.engine = require("containers.engine_utils").get_engine()
  end
end

return M
