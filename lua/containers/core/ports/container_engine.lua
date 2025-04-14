-- Defines the expected interface for container engines

return {
  list_containers = function()
    error("list_containers not implemented.")
  end,
  get_logs = function(id)
    error(id .. ": get_logs not implemented.")
  end,
  exec_in_container = function(id, command)
    error(id .. ": exec_in_container not implemented. Command:  " .. vim.inspect(command))
  end,
  start_container = function(id)
    error(id .. ": start_container not implemented.")
  end,
  stop_container = function(id)
    error(id .. ": stop_container not implemented.")
  end,
  kill_container = function(id)
    error(id .. ": kill_container not implemented.")
  end,
  inspect_container = function(id)
    error(id .. ": inspect_container not implemented.")
  end
}
