---@module 'sandbox.adapters.nerdctl.containers.follow_logs'
--- Nerdctl Adapter: Stream a container's logs live (`nerdctl logs -f <id>`)

local M = {}

--- Stream logs for a container until stopped or the process exits.
--- @param container_id string
--- @param on_line fun(line: string)
--- @param on_exit? fun(code: integer|nil)
--- @return table handle with a `:stop()` method
function M.follow_logs(container_id, on_line, on_exit)
  -- stdout and stderr are two independent byte streams; `vim.system` invokes
  -- their callbacks separately as each pipe has data, in whatever order the
  -- OS delivers them. A single shared buffer here would splice a stdout
  -- chunk that has not seen its newline yet with an unrelated stderr chunk
  -- that arrives first -- e.g. stdout emits "foo" (no newline), then stderr
  -- emits "bar\n": a shared buffer turns that into one line "foobar" that
  -- never existed in either stream. Each stream gets its own trailing-partial
  -- buffer so a line is only ever completed by more of the *same* stream.
  local function make_stream_buffer()
    local buffered = ""
    return {
      feed = function(data)
        buffered = buffered .. data
        local chunks = vim.split(buffered, "\n", { plain = true })
        buffered = table.remove(chunks) or ""
        return chunks
      end,
      flush = function()
        local last = buffered
        buffered = ""
        return last
      end,
    }
  end

  local stdout_buf = make_stream_buffer()
  local stderr_buf = make_stream_buffer()

  local function make_on_output(stream_buf)
    return function(_, data)
      if not data then
        return
      end
      local chunks = stream_buf.feed(data)
      if #chunks > 0 then
        vim.schedule(function()
          for _, line in ipairs(chunks) do
            on_line(line)
          end
        end)
      end
    end
  end

  local job = vim.system(
    { "nerdctl", "logs", "-f", container_id },
    { stdout = make_on_output(stdout_buf), stderr = make_on_output(stderr_buf) },
    function(obj)
      local leftover_out = stdout_buf.flush()
      local leftover_err = stderr_buf.flush()
      if leftover_out ~= "" or leftover_err ~= "" then
        vim.schedule(function()
          if leftover_out ~= "" then
            on_line(leftover_out)
          end
          if leftover_err ~= "" then
            on_line(leftover_err)
          end
        end)
      end
      if on_exit then
        vim.schedule(function()
          on_exit(obj.code)
        end)
      end
    end
  )

  return {
    stop = function()
      job:kill("sigterm")
    end,
  }
end

return M
