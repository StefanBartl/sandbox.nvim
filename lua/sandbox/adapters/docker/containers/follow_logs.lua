---@module 'sandbox.adapters.docker.containers.follow_logs'
--- Docker Adapter: Stream a container's logs live (`docker logs -f <id>`)

local M = {}

--- Stream logs for a container until stopped or the process exits.
--- @param container_id string
--- @param on_line fun(line: string)
--- @param on_exit? fun(code: integer|nil)
--- @return table handle with a `:stop()` method
function M.follow_logs(container_id, on_line, on_exit)
  local buffered = ""

  local function on_output(_, data)
    if not data then
      return
    end
    buffered = buffered .. data
    local chunks = vim.split(buffered, "\n", { plain = true })
    buffered = table.remove(chunks) or ""
    if #chunks > 0 then
      vim.schedule(function()
        for _, line in ipairs(chunks) do
          on_line(line)
        end
      end)
    end
  end

  local job = vim.system(
    { "docker", "logs", "-f", container_id },
    { stdout = on_output, stderr = on_output },
    function(obj)
      if buffered ~= "" then
        local last = buffered
        vim.schedule(function()
          on_line(last)
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
