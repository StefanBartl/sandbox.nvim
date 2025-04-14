-- Adapter: Podman implementation of ContainerEngine interface

local M = {}
local unpack = table.unpack or unpack -- for backwards comptability

--- List all containers (running or stopped)
function M.list_containers()
  local output = vim.fn.system({ "podman", "ps", "-a", "--format", "json" })

  if vim.v.shell_error ~= 0 then
    vim.notify("Podman error: " .. output, vim.log.levels.ERROR)
    return {}
  end

  local ok, result = pcall(vim.fn.json_decode, output)
  if not ok then
    vim.notify("JSON decode error: " .. result, vim.log.levels.ERROR)
    return {}
  end

  return result
end

function M.get_logs(container_id)
  local output = vim.fn.system({ "podman", "logs", container_id })

  if vim.v.shell_error ~= 0 then
    vim.notify("Podman logs error: " .. output, vim.logs.levels.ERROR)
    return { "[nvim-containers] Failed to get logs for: " .. container_id}
  end
  return vim.split(output, "\n", { plain = true })
end

function M.exec_in_container(container_id, command)
  command = command or { "sh" }
  local args = { "podman", "exec", "-it", container_id, unpack(command) }

  vim.cmd("vnew")
  local buf = vim.api.nvim_get_current_buf()
  vim.fn.termopen(args)
  vim.api.nvim_buf_set_name(buf, "nvim-containers://exec/" .. container_id)
  vim.bo[buf].bufhidden = "wipe"
end

function M.start_container(container_id)
  local output = vim.fn.system({ "podman", "start", container_id })

  if vim.v.shell_error ~= 0 then
    vim.notify("Podman start error: " .. output, vim.logd.levels.ERROR)
    return false
  end

  vim.notify("Container started: " .. container_id, vim.log.levels.INFO)
  return true
end

function M.stop_container(container_id)
  local cmd = { "podman", "stop", "--timeout", "1", container_id }

  vim.fn.jobstart(cmd, {
    on_exit = function(_, code, _)
      vim.schedule(function()
        if code == 0 then
          vim.notify("Container stopped: " .. container_id, vim.log.levels.INFO)
        else
          vim.notify("Error stopping container: exit code " .. code, vim.log.levels.ERROR)
        end
      end)
    end,
  })
end

function M.kill_container(container_id)
  local cmd = { "podman", "kill", container_id }

  vim.fn.jobstart(cmd, {
    on_exit = function(_, code, _)
      vim.schedule(function()
        if code == 0 then
          vim.notify("Container killed: " .. container_id, vim.log.levels.INFO)
        else
          vim.notify("Error killing container (code " .. code .. "): " .. container_id, vim.log.levels.ERROR)
        end
      end)
    end,
  })
end

function M.remove_container(container_id)
  local cmd = { "podman", "rm", container_id }

  vim.fn.jobstart(cmd, {
    on_exit = function(_, code, _)
      vim.schedule(function()
        if code == 0 then
          vim.notify("Container removed: " .. container_id, vim.log.levels.INFO)
        else
          vim.notify("Failed to remove container: " .. container_id, vim.log.levels.ERROR)
        end
      end)
    end,
  })
end

function M.prune_containers()
  local cmd = { "podman", "container", "prune", "-f" }

  vim.fn.jobstart(cmd, {
    on_exit = function(_, code, _)
      vim.schedule(function()
        if code == 0 then
          vim.notify("Pruned all stopped containers", vim.log.levels.INFO)
        else
          vim.notify("Failed to prune containers", vim.log.levels.ERROR)
        end
      end)
    end,
  })
end

function M.inspect_container(container_id)
  local output = vim.fn.system({ "podman", "inspect", container_id })

  local ok, result = pcall(vim.fn.json_decode, output)
  if not ok or type(result) ~= "table" then
    return { "[nvim-containers] Invalid JSON output:\n" .. output }
  end

  if vim.v.shell_error ~= 0 or result[1] == nil then
    return { "[nvim-containers] Error inspecting container:\n" .. output }
  end

  return result[1]
end

function M.list_images()
  local output = vim.fn.system({ "podman", "images", "--format", "json" })

  if vim.v.shell_error ~= 0 then
    return { "[nvim-containers] Failed to list images: " .. output }
  end

  local ok, result = pcall(vim.fn.json_decode, output)
  if not ok then
    return { "[nvim-containers] Invalid image JSON output" }
  end

  return result
end

function M.pull_image(name)
  local output = vim.fn.system({ "podman", "pull", name })

  if vim.v.shell_error ~= 0 then
    return false, output
  end

  return true
end

function M.remove_image(id)
  local output = vim.fn.system({ "podman", "rmi", id })

  if vim.v.shell_error ~= 0 then
    return false, output
  end

  return true
end

function M.remove_image(id)
  vim.fn.jobstart({ "podman", "rmi", id }, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        vim.schedule(function()
          vim.notify(table.concat(data, "\n"), vim.log.levels.INFO)
        end)
      end
    end,
    on_stderr = function(_, data)
      if data then
        vim.schedule(function()
          vim.notify(table.concat(data, "\n"), vim.log.levels.ERROR)
        end)
      end
    end,
    on_exit = function(_, code)
      vim.schedule(function()
        if code == 0 then
          vim.notify("Image removed: " .. id, vim.log.levels.INFO)
        else
          vim.notify("Failed to remove image: " .. id, vim.log.levels.ERROR)
        end
      end)
    end,
  })
end

return M
