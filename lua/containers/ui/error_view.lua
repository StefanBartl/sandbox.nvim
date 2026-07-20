-- file: lua/containers/ui/error_view.lua

--- Display an error message in a new split buffer
--- @param lines string[]  -- error lines to show
return function(lines)
  require("lib.nvim.window").open_named_scratch(
    "sandbox.nvim://error-view", lines, { filetype = "log", split = "below" }
  )
end
