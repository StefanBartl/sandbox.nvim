-- Defines the expected interface for container engines

return {

-- Container interfaces
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
  remove_container = function(id)
    error(id .. ": remove_container not implemented.")
  end,
  prune_containers = function()
    error("prune_containers not implemented.")
  end,
  inspect_container = function(id)
    error(id .. ": inspect_container not implemented.")
  end,

-- Image interfaces
  list_images = function()
    error("list_images not implemented")
  end,
  pull_image = function(image_name)
    error(image_name .. ": pull_image not implemented")
  end,
  remove_image = function(image_id)
    error(image_id .. ": remove_image not implemented")
  end,
  prune_images = function()
    error("prune_images not implemented")
  end,
}
