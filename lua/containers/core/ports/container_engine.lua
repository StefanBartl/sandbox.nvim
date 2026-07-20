-- Defines the expected interface for container engines

return {

-- Container interfaces
  --- @return table[]|nil containers, string|nil err
  list_containers = function()
    error("list_containers not implemented.")
  end,
  --- @param id string
  --- @return string[]|nil lines, string|nil err
  get_logs = function(id)
    error(id .. ": get_logs not implemented.")
  end,
  exec_in_container = function(id, command)
    error(id .. ": exec_in_container not implemented. Command:  " .. vim.inspect(command))
  end,
  --- @param id string
  --- @return boolean ok, string|nil err
  start_container = function(id)
    error(id .. ": start_container not implemented.")
  end,
  --- @param id string
  --- @param _on_done? fun(ok: boolean, err: string|nil)
  stop_container = function(id, _on_done)
    error(id .. ": stop_container not implemented.")
  end,
  --- @param id string
  --- @param _on_done? fun(ok: boolean, err: string|nil)
  kill_container = function(id, _on_done)
    error(id .. ": kill_container not implemented.")
  end,
  --- @param id string
  --- @param _on_done? fun(ok: boolean, err: string|nil)
  remove_container = function(id, _on_done)
    error(id .. ": remove_container not implemented.")
  end,
  --- @param _on_done? fun(ok: boolean, err: string|nil)
  prune_containers = function(_on_done)
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
