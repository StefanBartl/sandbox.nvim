---@module 'sandbox.util.project_config'
--- Reads a per-project `.sandboxrc` file (simple `key=value` lines) from the
--- current working directory, so a repo that specifically needs Docker or
--- Podman can pin its engine regardless of the global/detected default.

local M = {}

--- Read an `engine=docker|podman|nerdctl` override from `.sandboxrc` in the cwd.
---
--- The second return distinguishes "no override to apply" from "the file
--- names one, but its value is not recognized" -- collapsing both onto a
--- bare `nil` would make a typo in a file the user wrote specifically to pin
--- an engine behave exactly like never having written the file at all.
--- @return Sandbox.Engine|nil name
--- @return boolean invalid  true when an `engine=` line exists but its value is not one of the three known engines
function M.read_engine_override()
  local path = vim.fn.getcwd() .. "/.sandboxrc"
  if vim.fn.filereadable(path) ~= 1 then
    return nil, false
  end

  for _, line in ipairs(vim.fn.readfile(path)) do
    -- The value is captured greedily (not `%S+`) so a trailing stray token
    -- ("engine = podman extra") still reaches the validity check below
    -- instead of silently failing to match the line at all.
    local key, value = line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
    if key == "engine" then
      if value == "docker" or value == "podman" or value == "nerdctl" then
        return value, false
      end
      return nil, true
    end
  end

  return nil, false
end

return M
