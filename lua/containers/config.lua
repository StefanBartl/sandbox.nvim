-- Configuration for the plugin

local M = {}

M.options = {
  engine = nil, -- no default here anymore, to allow dynamic detection
}

--- Setup configuration with user options
--- @param opts table|nil: Optional user configuration
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.options, opts or {})

  -- If no engine is explicitly set, detect automatically
  if not M.options.engine then
    M.options.engine = require("containers.engine_utils").get_engine()
  end
end

return M
