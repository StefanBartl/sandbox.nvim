---@module 'sandbox.adapters.nerdctl.containers.get_logs'
--- Nerdctl Adapter: Function to retrieve logs of a container

local run_argv = require("sandbox.util.run_argv")

local M = {}

--- Retrieve the logs of a specific container
--- @param container_id string: ID or name of the container to retrieve logs from
--- @param on_done? fun(...) Optional: when given, runs asynchronously and
---        delivers exactly the values the synchronous form returns.
--- @return string[]|nil lines, string|nil err
function M.get_logs(container_id, on_done)
  local argv = { "nerdctl", "logs", container_id }

  -- Optional async path. `run_blocking_captured` blocks the UI thread for
  -- the whole round-trip to the container daemon, which for this command is
  -- long enough to feel (100-500ms typically, more with Docker Desktop on
  -- Windows). Passing `on_done` runs it through `run_async_captured`
  -- instead; the parsing is shared between both paths, so the synchronous
  -- contract is unchanged for callers that pass nothing.
  local function parse(ok, output)
    if not ok then
      return nil, output
    end

    return vim.split(output, "\n", { plain = true }), nil
  end

  if on_done then
    run_argv.run_async_captured(argv, function(ok, output)
      on_done(parse(ok, output))
    end)
    return
  end

  return parse(run_argv.run_blocking_captured(argv))
end

return M
