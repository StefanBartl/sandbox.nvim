---@module 'sandbox.core.ports.container_engine'
--- Defines the expected interface for container engines

return {

  -- Container interfaces
  --
  -- The five read-heavy operations (list_containers, get_logs,
  -- inspect_container, stats_container, top_container) take an optional
  -- `on_done`. Without it they behave exactly as before and return
  -- synchronously; with it the adapter runs the daemon round-trip through
  -- `run_async_captured` and delivers the identical values to the callback.
  -- Those five are singled out because they are the ones long enough to be
  -- felt (100-500ms, more under Docker Desktop on Windows) -- the short
  -- mutating calls stay synchronous.
  --- @param _on_done? fun(containers: table[]|nil, err: string|nil)
  --- @param _opts? { progress?: boolean } Only meaningful with _on_done.
  --- @return table[]|nil containers, string|nil err
  list_containers = function(_on_done, _opts)
    error("list_containers not implemented.")
  end,
  --- @param id string
  --- @param _on_done? fun(lines: string[]|nil, err: string|nil)
  --- @return string[]|nil lines, string|nil err
  get_logs = function(id, _on_done)
    error(id .. ": get_logs not implemented.")
  end,
  --- Stream a container's logs (`logs -f`) until stopped or the process exits.
  --- @param id string
  --- @param on_line fun(line: string)
  --- @param on_exit? fun(code: integer|nil)
  --- @return table handle with a `:stop()` method
  follow_logs = function(id, on_line, on_exit)
    error(id .. ": follow_logs not implemented.")
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
  --- @param _on_done? fun(lines: string[]|nil, err: string|nil)
  --- @return string[]|nil lines, string|nil err
  stats_container = function(id, _on_done)
    error(id .. ": stats_container not implemented.")
  end,
  --- @param id string
  --- @param _on_done? fun(lines: string[]|nil, err: string|nil)
  --- @return string[]|nil lines, string|nil err
  top_container = function(id, _on_done)
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
  inspect_container = function(id, _on_done)
    error(id .. ": inspect_container not implemented.")
  end,

  -- Image interfaces
  --- @return table[]|nil images, string|nil err
  list_images = function()
    error("list_images not implemented")
  end,
  --- Pull an image without blocking the UI thread.
  --- @param image_name string
  --- @param on_done fun(ok: boolean, err: string|nil)
  --- @return table handle with a `:stop()` method
  pull_image = function(image_name, on_done)
    error(image_name .. ": pull_image not implemented")
  end,
  --- Push an image to a remote registry without blocking the UI thread.
  --- @param image_name string
  --- @param on_done fun(ok: boolean, err: string|nil)
  --- @return table handle with a `:stop()` method
  push_image = function(image_name, on_done)
    error(image_name .. ": push_image not implemented")
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

  -- Network interfaces
  --- @return table[]|nil networks, string|nil err
  list_networks = function()
    error("list_networks not implemented")
  end,
  --- @param name string
  --- @return boolean ok, string|nil err
  create_network = function(name)
    error(name .. ": create_network not implemented.")
  end,
  --- @param name string
  --- @param _on_done? fun(ok: boolean, err: string|nil)
  remove_network = function(name, _on_done)
    error(name .. ": remove_network not implemented.")
  end,
  --- @param name string
  --- @return table|string[]
  inspect_network = function(name)
    error(name .. ": inspect_network not implemented.")
  end,
  --- @param network string
  --- @param container_id string
  --- @return boolean ok, string|nil err
  connect_network = function(network, container_id)
    error("connect_network not implemented. " .. network .. " <- " .. container_id)
  end,
  --- @param network string
  --- @param container_id string
  --- @return boolean ok, string|nil err
  disconnect_network = function(network, container_id)
    error("disconnect_network not implemented. " .. network .. " <- " .. container_id)
  end,
  --- @param _on_done? fun(ok: boolean, err: string|nil)
  prune_networks = function(_on_done)
    error("prune_networks not implemented")
  end,

  -- Registry interfaces
  --- Authenticate against a registry (password piped via stdin, never argv).
  --- @param username string
  --- @param password string
  --- @param registry? string defaults to Docker Hub when omitted
  --- @return boolean ok, string|nil err
  login_registry = function(username, password, registry)
    error("login_registry not implemented. username: " .. username .. " registry: " .. tostring(registry))
  end,
  --- @param registry? string defaults to Docker Hub when omitted
  --- @return boolean ok, string|nil err
  logout_registry = function(registry)
    error("logout_registry not implemented. registry: " .. tostring(registry))
  end,
}
