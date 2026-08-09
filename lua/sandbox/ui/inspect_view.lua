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

  vim.keymap.set("n", "q", function()
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end, { buffer = bufnr, desc = "sandbox: close inspect buffer", nowait = true, silent = true })
end
