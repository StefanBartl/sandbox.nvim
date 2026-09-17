---@module 'sandbox.util.line_stream'
--- Turning a subprocess's stdout/stderr chunks into whole lines.
---
--- `vim.system`'s function handlers deliver whatever libuv read, which is not
--- lines: a chunk can end mid-line and the rest arrive in the next one. Any
--- consumer that splits each chunk on its own will cut such a line in two, so
--- the trailing partial has to be held back until more of the *same* stream
--- completes it. Each stream therefore needs its own buffer -- a line must
--- never be completed by output from the other one.
---
--- This also strips a trailing CR, for the same reason
--- `run_argv.normalize_eol` does on the captured path: `vim.system`'s
--- `text = true` only covers the stdout/stderr it captures itself, never a
--- function handler, so on Windows every line would otherwise carry one.
--- Kept here rather than in each adapter because all three container engines
--- stream logs identically, and a rule that lives in three copies is a rule
--- that will eventually only be fixed in two.

local M = {}

---@class Sandbox.LineStream
---@field feed fun(data: string): string[]  Whole lines completed by this chunk
---@field flush fun(): string               Whatever never got its newline

---A buffer that accumulates chunks and hands back the lines they complete.
---@return Sandbox.LineStream
function M.new()
  local buffered = ""
  return {
    feed = function(data)
      buffered = buffered .. data
      local chunks = vim.split(buffered, "\n", { plain = true })
      -- The last element is either a partial line or "" (the chunk ended on a
      -- newline); either way it is not complete, so it stays buffered.
      buffered = table.remove(chunks) or ""
      for i = 1, #chunks do
        if chunks[i]:sub(-1) == "\r" then
          chunks[i] = chunks[i]:sub(1, -2)
        end
      end
      return chunks
    end,
    flush = function()
      local last = buffered
      buffered = ""
      if last:sub(-1) == "\r" then
        last = last:sub(1, -2)
      end
      return last
    end,
  }
end

return M
