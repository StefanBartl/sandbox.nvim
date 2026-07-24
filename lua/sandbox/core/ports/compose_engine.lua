---@module 'sandbox.core.ports.compose_engine'
---@brief Defines the expected interface for Compose orchestration.
---@description
--- Separate from the ContainerEngine port: compose operates on a whole
--- multi-container project (a compose file), not a single container/image/
--- volume/network resource, so its methods take a compose file path rather
--- than a container/image id.

return {
  --- @param file string path to the compose file
  --- @param _on_done? fun(ok: boolean, err: string|nil)
  up = function(file, _on_done)
    error(file .. ": up not implemented.")
  end,
  --- @param file string
  --- @param _on_done? fun(ok: boolean, err: string|nil)
  down = function(file, _on_done)
    error(file .. ": down not implemented.")
  end,
  --- @param file string
  --- @param _on_done? fun(ok: boolean, err: string|nil)
  restart = function(file, _on_done)
    error(file .. ": restart not implemented.")
  end,
  --- @param file string
  --- @return string[]|nil lines, string|nil err
  ps = function(file)
    error(file .. ": ps not implemented.")
  end,
  --- @param file string
  --- @return string[]|nil lines, string|nil err
  logs = function(file)
    error(file .. ": logs not implemented.")
  end,
}
