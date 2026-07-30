-- Podman Adapter: Pull image

local run_argv = require("sandbox.util.run_argv")

local M = {}

--- Pull an image by name without blocking the UI thread.
--- @param name string
--- @param on_done fun(ok: boolean, err: string|nil)
--- @return table handle with a `:stop()` method
function M.pull_image(name, on_done)
  return run_argv.run_async_captured({ "podman", "pull", name }, function(ok, output)
    -- Not `ok and nil or output`: in Lua that idiom collapses when the middle
    -- operand is nil, so it handed the pull/push log back as an error on every
    -- successful run.
    if ok then
      on_done(true, nil)
    else
      on_done(false, output)
    end
  end)
end

return M
