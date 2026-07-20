-- If the Neovim health module is available, register a health check for the plugin
if vim.health and vim.health.registry then
  -- Register "sandbox" under :checkhealth
  vim.health.registry["sandbox"] = function()
    -- When called, run the check function from containers.health
    require("containers.health").check()
  end
end
