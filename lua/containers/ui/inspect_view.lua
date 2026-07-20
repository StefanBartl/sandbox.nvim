--- @param data table | string[]
--- @param container_id string
return function(data, container_id)
  local lines

  if type(data) == "table" then
    lines = vim.split(vim.inspect(data), "\n", { plain = true })
  else
    lines = data -- already an error string[]
  end

  require("lib.nvim.window").open_named_scratch(
    "nvim-containers://inspect/" .. container_id, lines, { filetype = "lua", split = "left" }
  )
end
