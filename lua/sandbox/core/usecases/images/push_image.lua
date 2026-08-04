---@module 'sandbox.core.usecases.images.push_image'
--- Pushes a container image to a remote registry without blocking the UI thread.
--- @param engine table
--- @param image_name string
--- @param on_done fun(ok: boolean, err: string|nil)
--- @return table handle with a `:stop()` method
return function(engine, image_name, on_done)
  return engine.push_image(image_name, on_done)
end
