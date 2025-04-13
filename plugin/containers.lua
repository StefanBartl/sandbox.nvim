-- Command definitions for lazy-loading

vim.api.nvim_create_user_command("ContainerList", function()
  local core = require("containers")
  local engine = core.get_engine()
  local usecase = require("containers.core.usecases.list_containers")

  local ok, containers = pcall(usecase, engine)

  if not ok or type(containers) ~= "table" then
    local error_view = require("containers.ui.error_view")
    error_view({ "Failed to list containers:", vim.inspect(containers) })
    return
  end

  local view = require("containers.ui.list_view")
  view(containers)

end, {})

vim.api.nvim_create_user_command("ContainerLogs", function(opts)
  local engine = require("containers").get_engine()
  local usecase = require("containers.core.usecases.get_container_logs")
  local view = require("containers.ui.log_view")

  local id = opts.args
  if not id or id == "" then
    vim.notify("Usage: :ContainerLogs <container-id>", vim.log.levels.WARN)
    return
  end

  local ok, logs = pcall(usecase, engine, id)
  if not ok then
    vim.notify("Failed to get logs: " .. logs, vim.log.levels.ERROR)
    return
  end

  view(logs, id)
end, { nargs = 1 })
