---@module 'sandbox.util.project_config'
--- Reads a per-project `.sandboxrc` file (simple `key=value` lines) from the
--- current working directory, so a repo that specifically needs Docker or
--- Podman can pin its engine regardless of the global/detected default.

local M = {}

--- Read an `engine=docker|podman` override from `.sandboxrc` in the cwd.
--- @return Sandbox.Engine|nil
function M.read_engine_override()
  local path = vim.fn.getcwd() .. "/.sandboxrc"
  if vim.fn.filereadable(path) ~= 1 then
    return nil
  end

  for _, line in ipairs(vim.fn.readfile(path)) do
    local key, value = line:match("^%s*([%w_]+)%s*=%s*(%S+)%s*$")
    if key == "engine" and (value == "docker" or value == "podman") then
      return value
    end
  end

  return nil
end

return M
