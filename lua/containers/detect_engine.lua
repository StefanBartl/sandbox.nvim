-- Utility to detect available container engine

--- Check if a command is available on the system
--- @param cmd string
--- @return boolean
local function is_executable(cmd)
  return vim.fn.executable(cmd) == 1
end

--- Detect which container engine is available
--- @return "podman"|"docker"
return function()
  if is_executable("podman") then
    return "podman"
  elseif is_executable("docker") then
    return "docker"
  else
    vim.notify("[nvim-containers] No supported container engine (podman/docker) found in PATH.", vim.log.levels.ERROR)
    return "docker" -- fallback to docker to avoid crash, user will see error
  end
end
