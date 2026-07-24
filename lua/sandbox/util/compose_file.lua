-- Detect a docker-compose/compose/podman-compose file in the cwd or an
-- ancestor directory, matching the filenames docker compose/podman compose
-- look for themselves.

local CANDIDATES = {
  "docker-compose.yml", "docker-compose.yaml",
  "compose.yml", "compose.yaml",
  "podman-compose.yml", "podman-compose.yaml",
}

local M = {}

--- @return string|nil path to the nearest compose file, searching upward from cwd
function M.find()
  local found = vim.fs.find(CANDIDATES, { upward = true, path = vim.fn.getcwd() })
  return found[1]
end

return M
