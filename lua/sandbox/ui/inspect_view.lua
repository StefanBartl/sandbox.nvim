--- Render inspected metadata as a folded, indented Lua-table view (via
--- `vim.inspect`) instead of a flat dump, so large nested structures
--- (mounts, network settings, ...) can be collapsed to scan the shape
--- before diving into a section. Press `q` to close.
--- @param data table | string[]
--- @param container_id string
return function(data, container_id)
  local lines

  if type(data) == "table" then
    lines = vim.split(vim.inspect(data), "\n", { plain = true })
  else
    lines = data -- already an error string[]
  end

  local list_opts = require("sandbox.config").options
  local bufnr, winid = require("lib.nvim.window").open_named_scratch(
    "sandbox.nvim://inspect/" .. container_id,
    lines,
    { filetype = "lua", split = list_opts.list_split, size = list_opts.list_size }
  )

  vim.wo[winid].foldmethod = "indent"
  vim.wo[winid].foldlevel = 1

  -- Declared rather than hardcoded so `keymaps.inspect = { close = "<Esc>" }`
  -- can move it: `q` in a read-only scratch buffer is a reasonable default,
  -- not a universal one -- somebody who records macros wants it back.
  require("sandbox.ui.list_actions").bind_close(bufnr, "inspect", "close inspect buffer")
end
