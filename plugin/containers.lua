-- Command definitions for lazy-loading

vim.api.nvim_create_user_command("ContainerList", function()
  local core = require("containers")
  local engine = core.get_engine()
  local usecase = require("containers.core.usecases.list_containers")
  local view = require("containers.ui.list_view")

  local containers = usecase(engine)
  view(containers)
end, {})
