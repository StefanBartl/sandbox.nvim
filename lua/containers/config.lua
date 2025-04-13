-- Configuration for the plugin

local M = {}

M.options = {
  engine = "podman", -- default engine
}

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.options, opts or {})
end

return M

