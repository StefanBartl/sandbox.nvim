---@module 'sandbox.util.project_config'
--- Reads a per-project `.sandboxrc` file (simple `key=value` lines) from the
--- current working directory, so a repo that specifically needs Docker or
--- Podman can pin its engine regardless of the global/detected default.

local M = {}

--- PERF: `resolve_engine_name()` (sandbox/init.lua) is called from
--- statusline.status() on every redraw -- many times a second -- and falls
--- through to this function whenever no `vim.g.sandbox_engine` session
--- override is set, which is the common case. Without caching, that meant a
--- `filereadable()`/`readfile()` pair against `<cwd>/.sandboxrc` on every
--- single redraw, cwd unchanged or not. The answer only ever depends on the
--- cwd and that file's contents, so it is cached per cwd and re-read only
--- when the cwd actually changes -- the same event (`:cd`) that is the only
--- documented way this override is meant to change at all.
---@type { cwd: string, name: Sandbox.Engine|nil, invalid: boolean }|nil
local cache = nil

--- Read an `engine=docker|podman|nerdctl` override from `.sandboxrc` in the cwd.
---
--- The second return distinguishes "no override to apply" from "the file
--- names one, but its value is not recognized" -- collapsing both onto a
--- bare `nil` would make a typo in a file the user wrote specifically to pin
--- an engine behave exactly like never having written the file at all.
--- @return Sandbox.Engine|nil name
--- @return boolean invalid  true when an `engine=` line exists but its value is not one of the three known engines
function M.read_engine_override()
  local cwd = vim.fn.getcwd()
  if cache and cache.cwd == cwd then
    return cache.name, cache.invalid
  end

  local name, invalid = nil, false
  local path = cwd .. "/.sandboxrc"
  if vim.fn.filereadable(path) == 1 then
    for _, line in ipairs(vim.fn.readfile(path)) do
      -- The value is captured greedily (not `%S+`) so a trailing stray token
      -- ("engine = podman extra") still reaches the validity check below
      -- instead of silently failing to match the line at all.
      local key, value = line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
      if key == "engine" then
        if value == "docker" or value == "podman" or value == "nerdctl" then
          name = value
        else
          invalid = true
        end
        break
      end
    end
  end

  cache = { cwd = cwd, name = name, invalid = invalid }
  return name, invalid
end

return M
