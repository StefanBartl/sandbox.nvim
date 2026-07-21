-- Turns a raw adapter error (often multi-line docker/podman/wsl CLI stderr)
-- into a short, human-readable message suitable for a single vim.notify
-- popup. Common daemon-unreachable failures are mapped to an actionable
-- message; anything else falls back to the first line of the raw text,
-- capped in length. The full raw text should still be logged separately
-- via sandbox.logger for postmortem debugging.

local MAX_LEN = 200

local DOCKER_UNREACHABLE = "Docker daemon not reachable - is Docker Desktop running?"
local PODMAN_UNREACHABLE = "Podman not reachable - is the podman machine/service running?"

--- @type { pattern: string, message: string }[]
local KNOWN_PATTERNS = {
  { pattern = "docker daemon is not running", message = DOCKER_UNREACHABLE },
  { pattern = "cannot connect to the docker daemon", message = DOCKER_UNREACHABLE },
  { pattern = "error during connect", message = DOCKER_UNREACHABLE },
  { pattern = "dockerdesktoplinuxengine", message = DOCKER_UNREACHABLE },
  { pattern = "cannot connect to podman", message = PODMAN_UNREACHABLE },
  { pattern = "unable to connect to podman socket", message = PODMAN_UNREACHABLE },
}

--- @param raw_err string|nil
--- @return string
local function first_line(raw_err)
  if not raw_err or raw_err == "" then
    return "unknown error"
  end

  local line = raw_err:match("^[^\r\n]+") or raw_err
  line = line:gsub("^%s+", ""):gsub("%s+$", "")

  if line == "" then
    return "unknown error"
  end

  if #line > MAX_LEN then
    line = line:sub(1, MAX_LEN) .. "..."
  end

  return line
end

--- @param raw_err string|nil
--- @return string
return function(raw_err)
  if raw_err then
    local lower = raw_err:lower()
    for _, entry in ipairs(KNOWN_PATTERNS) do
      if lower:find(entry.pattern, 1, true) then
        return entry.message
      end
    end
  end

  return first_line(raw_err)
end
