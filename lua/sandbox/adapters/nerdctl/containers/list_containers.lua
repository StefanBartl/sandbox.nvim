---@module 'sandbox.adapters.nerdctl.containers.list_containers'
--- Nerdctl Adapter: Function to list all containers (running and stopped)

local run_argv = require("sandbox.util.run_argv")

local M = {}

--- @param on_done? fun(...) Optional: when given, runs asynchronously and
---        delivers exactly the values the synchronous form returns.
--- List all containers (running and stopped) using Nerdctl
--- Sorts containers: running first, then others.
--- @return table[]|nil containers, string|nil err
function M.list_containers(on_done)
  local argv = { "nerdctl", "ps", "-a", "--format", "{{json .}}" }

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

    local containers = {}
    local decode_errors = {}

    for _, line in ipairs(vim.split(output, "\n", { trimempty = true })) do
      local decode_ok, container = pcall(vim.fn.json_decode, line)
      if decode_ok and type(container) == "table" then
        table.insert(containers, {
          id = container.ID or "<no id>",
          name = container.Names or "<no name>",
          status = container.State or "unknown",
          image = container.Image or "<no image>",
        })
      else
        table.insert(decode_errors, tostring(line))
      end
    end

    table.sort(containers, function(a, b)
      if a.status == b.status then
        return a.name < b.name
      elseif a.status == "running" then
        return true
      elseif b.status == "running" then
        return false
      else
        return a.name < b.name
      end
    end)

    if #decode_errors > 0 then
      return containers, "JSON decode error(s):\n" .. table.concat(decode_errors, "\n")
    end

    return containers, nil
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
