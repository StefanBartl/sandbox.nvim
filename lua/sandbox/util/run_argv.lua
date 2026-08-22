---@module 'sandbox.util.run_argv'
--- Argv runner: uses lib.nvim's cross.run_argv when lib.nvim is installed,
--- falls back to plain vim.fn.system otherwise (lib.nvim stays an optional
--- dependency, matching containers/notify.lua's convention).

local ok, lib_run_argv = pcall(require, "lib.nvim.cross.run_argv")
-- Optional dependency, same convention as lib_run_argv above: a completed
-- env (PATH + session vars — docker/podman/nerdctl's socket/context binding
-- is exactly the session-bound-auth problem this module fixes) for
-- container CLIs that are easy to miss from a non-login Neovim start.
local ok_env, spawn_env = pcall(require, "lib.nvim.cross.run.env")

local M = {}

if ok then
  ---`lib.nvim.cross.run_argv.run_blocking_captured` takes no opts (no env
  ---support), so route through `vim.system` directly with a completed env
  ---when both lib.nvim's env module and `vim.system` are available; fall
  ---back to the unenriched `run_argv` call otherwise (old Neovim without
  ---`vim.system`, or lib.nvim installed without the env submodule).
  ---@param cmd string[]
  ---@param input? string
  ---@return boolean ok
  ---@return string output
  function M.run_blocking_captured(cmd, input)
    if ok_env and vim.system then
      local sok, obj = pcall(function()
        return vim.system(cmd, spawn_env.apply({ text = true, stdin = input })):wait()
      end)
      if not sok then
        return false, tostring(obj)
      end
      return obj.code == 0, obj.stdout or ""
    end
    return lib_run_argv.run_blocking_captured(cmd, input)
  end
else
  ---@param cmd string[]
  ---@param input? string
  ---@return boolean ok
  ---@return string output
  function M.run_blocking_captured(cmd, input)
    local out = vim.fn.system(cmd, input or "")
    return vim.v.shell_error == 0, out
  end
end

local ok_progress, progress_mod = pcall(require, "lib.nvim.progress")

---@internal
--- Label a progress handle by the operation rather than the full argv: the
--- image reference is often a long registry URL that would push the useful
--- part ("docker pull") out of a statusline. `{"docker","pull","nginx"}`
--- becomes "docker pull nginx", but a 200-char digest ref is truncated.
--- @param cmd string[]
--- @return string
local function progress_label(cmd)
  local verb = table.concat({ cmd[1] or "", cmd[2] or "" }, " ")
  local subject = cmd[3]
  if not subject or subject:sub(1, 1) == "-" then
    return vim.trim(verb)
  end
  if #subject > 40 then
    subject = subject:sub(1, 39) .. "…"
  end
  return vim.trim(verb .. " " .. subject)
end

---@internal
--- Start an indicator for `cmd`, or nil when lib.nvim isn't installed. The
--- style is read lazily from the live config so `setup()` ordering never
--- matters, and the whole thing is a no-op without lib.nvim - progress is a
--- soft dependency here exactly like `notify.lua`'s factory.
--- @param cmd string[]
--- @return table|nil
local function start_progress(cmd)
  if not ok_progress then
    return nil
  end
  local style = "auto"
  local ok_cfg, config = pcall(require, "sandbox.config")
  if ok_cfg then
    style = (config.options or {}).progress_style or style
  end
  local h = progress_mod.create({ title = "[sandbox.nvim]", style = style })
  h:update({ text = progress_label(cmd) })
  return h
end

--- Run `cmd` without blocking the UI thread, invoking `on_done(ok, output)`
--- once it exits. For long-running ops (`pull`, `prune`, `build`) where
--- `run_blocking_captured` would freeze Neovim until the process finishes.
---
--- Every caller gets a progress indicator for free: these commands are the
--- ones that can run for minutes (a `pull` over a slow link, a devcontainer
--- `build`) with nothing on screen until `on_done` fires. Cancelling it kills
--- the process, which the returned handle could already do - `on_cancel` just
--- routes the interactive styles ("float"/"kit") to the same `stop`.
--- `code` is passed as a third argument so callers can still report a bare
--- "exit code N" when the process failed without writing anything to stderr;
--- existing two-parameter callbacks simply ignore it.
--- `opts.progress = false` suppresses the indicator. That is for *ambient*
--- callers - the statusline component refreshing itself every few seconds -
--- where an indicator would be permanent noise rather than information. Every
--- user-initiated command should leave it on.
--- @param cmd string[]
--- @param on_done fun(ok: boolean, output: string, code: integer)
--- @param opts? { progress?: boolean }
--- @return table handle with a `:stop()` method
function M.run_async_captured(cmd, on_done, opts)
  local chunks = {}

  local function collect(_, data)
    if data and data ~= "" then
      chunks[#chunks + 1] = data
    end
  end

  local progress = nil
  if not (opts and opts.progress == false) then
    progress = start_progress(cmd)
  end

  local spawn_opts = { stdout = collect, stderr = collect }
  if ok_env then
    spawn_opts = spawn_env.apply(spawn_opts)
  end
  local job = vim.system(cmd, spawn_opts, function(obj)
    vim.schedule(function()
      -- A cancelled job also exits non-zero, but `request_cancel` already
      -- closed the indicator with its own message - reporting "failed" on top
      -- of it would blame the user's own abort on the command.
      if progress and not progress.cancelled then
        -- Report the outcome, not just "done": a failed pull is the case where
        -- the user most wants to know the indicator stopped for a reason.
        if obj.code == 0 then
          progress:finish(progress_label(cmd) .. " done")
        else
          progress:finish(progress_label(cmd) .. " failed (exit " .. tostring(obj.code) .. ")")
        end
      end
      on_done(obj.code == 0, table.concat(chunks), obj.code)
    end)
  end)

  local function stop()
    job:kill("sigterm")
  end

  if progress then
    progress:on_cancel(stop)
  end

  return { stop = stop }
end

return M
