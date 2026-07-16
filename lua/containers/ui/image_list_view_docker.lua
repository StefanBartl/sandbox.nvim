--- View for listing all Docker or Podman images
--- @param images table[]
return function(images)
  if type(images) ~= "table" then
    vim.notify("[nvim-containers] Invalid image list: not a table", vim.log.levels.ERROR)
    return
  end

  local lines = {}
  for _, image in ipairs(images) do
    table.insert(lines, string.format(
      "[%s:%s] %s (%s)",
      image.repository or "<none>",
      image.tag or "<none>",
      image.id and image.id:sub(1, 12) or "<no id>",
      image.size or "unknown size"
    ))
  end

  require("lib.nvim.window").open_named_scratch(
    "nvim-containers://image-list", lines, { filetype = "log", split = "left" }
  )
end
