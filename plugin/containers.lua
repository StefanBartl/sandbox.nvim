-- If the Neovim health module is available, register a health check for the plugin
if vim.health and vim.health.registry then
  -- Register "nvim-containers" under :checkhealth
  vim.health.registry["nvim-containers"] = function()
    -- When called, run the check function from containers.health
    require("containers.health").check()
  end
end
