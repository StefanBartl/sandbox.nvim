--- Display a list of containers in a vertical split buffer
--- @param containers table[]: List of standardized container objects (id, name, status, image)
return function(containers)
  if type(containers) ~= "table" then
    vim.notify("[nvim-containers] Invalid container list: not a table", vim.log.levels.ERROR)
    return
  end

  local lines = {}
  for _, container in ipairs(containers) do
    table.insert(lines, string.format(
      "[%s] %s (%s)",
      container.status or "unknown",
      container.name or "<no name>",
      container.id and container.id:sub(1, 12) or "<no id>"
    ))
  end

  require("lib.nvim.window").open_named_scratch(
    "nvim-containers://container-list", lines, { filetype = "log", split = "left" }
  )
end
