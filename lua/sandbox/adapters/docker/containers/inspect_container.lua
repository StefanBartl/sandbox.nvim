-- Docker Adapter: Function to inspect a container

local run_argv = require("sandbox.util.run_argv")

local M = {}

--- Inspect a specific container and return its detailed metadata
--- @param container_id string: ID or name of the container to inspect
--- @param on_done? fun(...) Optional: when given, runs asynchronously and
---        delivers exactly the values the synchronous form returns.
--- @return table|string[]: Container metadata as a table, or error message as string[]
function M.inspect_container(container_id, on_done)
  local argv = { "docker", "inspect", container_id }

  -- Optional async path. `run_blocking_captured` blocks the UI thread for
  -- the whole round-trip to the container daemon, which for this command is
  -- long enough to feel (100-500ms typically, more with Docker Desktop on
  -- Windows). Passing `on_done` runs it through `run_async_captured`
  -- instead; the parsing is shared between both paths, so the synchronous
  -- contract is unchanged for callers that pass nothing.
  local function parse(ok, output)
    -- Try to decode JSON output
    local decode_ok, result = pcall(vim.fn.json_decode, output)
    if not decode_ok or type(result) ~= "table" then
      return { "[sandbox.nvim] Invalid JSON output:\n" .. output }
    end

    -- Handle shell errors or missing result
    if not ok or result[1] == nil then
      return { "[sandbox.nvim] Error inspecting container:\n" .. output }
    end

    return result[1]
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
