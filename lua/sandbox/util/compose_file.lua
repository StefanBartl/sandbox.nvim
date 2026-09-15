---@module 'sandbox.util.compose_file'
--- Detect a docker-compose/compose/podman-compose file in the cwd or an
--- ancestor directory, matching the filenames docker compose/podman compose
--- look for themselves. Also a static peek at what it declares
--- (`M.services`), entirely separate from asking an engine.

local CANDIDATES = {
  "docker-compose.yml",
  "docker-compose.yaml",
  "compose.yml",
  "compose.yaml",
  "podman-compose.yml",
  "podman-compose.yaml",
}

local M = {}

--- @return string|nil path to the nearest compose file, searching upward from cwd
function M.find()
  local found = vim.fs.find(CANDIDATES, { upward = true, path = vim.fn.getcwd() })
  return found[1]
end

--- The service names declared under `services:` in the compose file at
--- `path`, sorted. A static read of the file itself -- unlike
--- `compose_commands.ps` (asks the engine what is actually running), this
--- costs nothing and works whether or not the engine, or even the compose
--- CLI, is installed.
---
--- Decoded with `lib.lua.yaml` -- the same deliberately minimal decoder
--- `data.nvim`'s `:YAML` commands use (no anchors, no flow style; see that
--- module's own doc comment). A compose file leaning on YAML anchors
--- (`&defaults`/`<<: *defaults` for shared service config) will not decode
--- correctly here -- that surfaces as `nil, err` rather than a wrong
--- answer, so a caller can fall back to `docker compose config --services`
--- for that case rather than trust a silently incomplete list.
---@param path string
---@return string[]|nil services sorted service names
---@return string|nil err
function M.services(path)
  local content, read_err = require("lib.nvim.fs.read")(path)
  if not content then
    return nil, "cannot be read: " .. tostring(read_err)
  end

  local decoded, decode_err = require("lib.lua.yaml").simple_parse(content)
  if not decoded then
    return nil, decode_err or "invalid YAML"
  end

  local services = decoded.services
  if type(services) ~= "table" then
    return nil, "no 'services:' key found"
  end
  if vim.islist(services) then
    -- A real compose file's `services:` is a map (service name -> config);
    -- a list here is malformed input. Reject it rather than iterating it
    -- with `pairs` below, which would silently hand back stringified
    -- array indices ("1", "2", ...) as if they were service names.
    return nil, "'services:' is a list, not a map of service name -> config"
  end

  ---@type string[]
  local names = {}
  for name in pairs(services) do
    names[#names + 1] = tostring(name)
  end
  table.sort(names)
  return names, nil
end

return M
