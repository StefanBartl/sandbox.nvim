local run_argv = require("sandbox.util.run_argv")

local M = {}

function M.inspect_container(container_id)
  local ok, output = run_argv.run_blocking_captured({ "podman", "inspect", container_id })

  local decode_ok, result = pcall(vim.fn.json_decode, output)
  if not decode_ok or type(result) ~= "table" then
    return { "[sandbox.nvim] Invalid JSON output:\n" .. output }
  end

  if not ok or result[1] == nil then
    return { "[sandbox.nvim] Error inspecting container:\n" .. output }
  end

  return result[1]
end

return M
