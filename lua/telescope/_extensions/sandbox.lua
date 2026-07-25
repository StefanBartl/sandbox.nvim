---@module 'telescope._extensions.sandbox'
--- Registers the "sandbox" telescope.nvim extension. Optional: only loaded
--- when the user calls `require("telescope").load_extension("sandbox")`
--- (or `:Telescope load_extension sandbox`) -- telescope.nvim itself is not
--- a dependency of sandbox.nvim's own setup() path.
---
--- Usage: :Telescope sandbox containers|images|wsl

return require("telescope").register_extension({
  exports = {
    containers = require("sandbox.telescope.containers"),
    images = require("sandbox.telescope.images"),
    wsl = require("sandbox.telescope.wsl"),
  },
})
