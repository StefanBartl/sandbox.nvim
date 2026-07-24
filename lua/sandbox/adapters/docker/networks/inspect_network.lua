-- Docker Adapter: Function to inspect a network

local run_argv = require("sandbox.util.run_argv")

local M = {}

--- Inspect a specific network and return its detailed metadata
--- @param name string
--- @return table|string[]: Network metadata as a table, or error message as string[]
function M.inspect_network(name)
  local ok, output = run_argv.run_blocking_captured({ "docker", "network", "inspect", name })

  local decode_ok, result = pcall(vim.fn.json_decode, output)
  if not decode_ok or type(result) ~= "table" then
    return { "[sandbox.nvim] Invalid JSON output:\n" .. output }
  end

  if not ok or result[1] == nil then
    return { "[sandbox.nvim] Error inspecting network:\n" .. output }
  end

  return result[1]
end

return M
