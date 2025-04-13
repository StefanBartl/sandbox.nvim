-- Defines the expected interface for container engines

return {
  list_containers = function()
    error("list_containers not implemented")
  end,
  get_logs = function(_id)
    error("get_logs not implemented")
  end,
  exec_in_container = function(_id, command)
    error("exec_in_container not implemented")
  end,
--  start_container = function(_id)
--    error("start_container not implemented")
--  end,
--  stop_container = function(_id)
--    error("stop_container not implemented")
--  end,
}
