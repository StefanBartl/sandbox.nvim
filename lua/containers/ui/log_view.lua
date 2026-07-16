--- Display logs of a container in a vertical split buffer
--- If a buffer for the container already exists, it will be reused and updated
--- @param lines string[]: Lines of log output
--- @param container_id string: ID or name of the container
return function(lines, container_id)
  local bufnr = require("lib.nvim.window").open_named_scratch(
    "nvim-containers://logs/" .. container_id, lines, { filetype = "log", split = "left" }
  )
  vim.bo[bufnr].modifiable = false
end
