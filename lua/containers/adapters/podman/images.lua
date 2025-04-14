--[[
  Podman Image Adapter

  Implements image-related operations of the ContainerEngine port
  for Podman: list, pull, remove, prune
]]

local M = {}

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

function M.prune_images()
  vim.fn.jobstart({ "podman", "image", "prune", "-f" }, {
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
          vim.notify("Image prune completed", vim.log.levels.INFO)
        else
          vim.notify("Image prune failed", vim.log.levels.ERROR)
        end
      end)
    end,
  })
end

return M
