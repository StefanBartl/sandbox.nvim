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
  restart_container = function(id, _on_done)
    error(id .. ": restart_container not implemented.")
  end,
  --- @param id string
  --- @param _on_done? fun(ok: boolean, err: string|nil)
  pause_container = function(id, _on_done)
    error(id .. ": pause_container not implemented.")
  end,
  --- @param id string
  --- @param _on_done? fun(ok: boolean, err: string|nil)
  unpause_container = function(id, _on_done)
    error(id .. ": unpause_container not implemented.")
  end,
  --- @param id string
  --- @param _new_name string
  --- @return boolean ok, string|nil err
  rename_container = function(id, _new_name)
    error(id .. ": rename_container not implemented.")
  end,
  --- @param id string
  --- @return string[]|nil lines, string|nil err
  stats_container = function(id)
    error(id .. ": stats_container not implemented.")
  end,
  --- @param id string
  --- @return string[]|nil lines, string|nil err
  top_container = function(id)
    error(id .. ": top_container not implemented.")
  end,
  --- @param src string
  --- @param dest string
  --- @return boolean ok, string|nil err
  cp_container = function(src, dest)
    error("cp_container not implemented. " .. src .. " -> " .. dest)
  end,
  --- @param opts table
  --- @param _on_done? fun(ok: boolean, result: string|nil)
  run_container = function(opts, _on_done)
    error("run_container not implemented. opts: " .. vim.inspect(opts))
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
  --- @return table[]|nil images, string|nil err
  list_images = function()
    error("list_images not implemented")
  end,
  --- @param image_name string
  --- @return boolean ok, string|nil err
  pull_image = function(image_name)
    error(image_name .. ": pull_image not implemented")
  end,
  --- @param image_id string
  --- @param _on_done? fun(ok: boolean, err: string|nil)
  remove_image = function(image_id, _on_done)
    error(image_id .. ": remove_image not implemented")
  end,
  --- @param _on_done? fun(ok: boolean, err: string|nil)
  prune_images = function(_on_done)
    error("prune_images not implemented")
  end,
  --- @param source string
  --- @param target string
  --- @return boolean ok, string|nil err
  tag_image = function(source, target)
    error("tag_image not implemented. " .. source .. " -> " .. target)
  end,

-- Volume interfaces
  --- @return table[]|nil volumes, string|nil err
  list_volumes = function()
    error("list_volumes not implemented")
  end,
  --- @param name string
  --- @return boolean ok, string|nil err
  create_volume = function(name)
    error(name .. ": create_volume not implemented.")
  end,
  --- @param name string
  --- @param _on_done? fun(ok: boolean, err: string|nil)
  remove_volume = function(name, _on_done)
    error(name .. ": remove_volume not implemented.")
  end,
  --- @param name string
  --- @return table|string[]
  inspect_volume = function(name)
    error(name .. ": inspect_volume not implemented.")
  end,
  --- @param _on_done? fun(ok: boolean, err: string|nil)
  prune_volumes = function(_on_done)
    error("prune_volumes not implemented")
  end,
  --- @param image string
  --- @param path string
  --- @return boolean ok, string|nil err
  save_image = function(image, path)
    error("save_image not implemented. " .. image .. " -> " .. path)
  end,
  --- @param path string
  --- @return boolean ok, string|nil err
  load_image = function(path)
    error(path .. ": load_image not implemented.")
  end,
  --- @param image string
  --- @return string[]|nil lines, string|nil err
  history_image = function(image)
    error(image .. ": history_image not implemented.")
  end,
  --- @param image string
  --- @return table|string[]
  inspect_image = function(image)
    error(image .. ": inspect_image not implemented.")
  end,
}
