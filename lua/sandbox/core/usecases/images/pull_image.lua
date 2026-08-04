---@module 'sandbox.core.usecases.images.pull_image'
--- Pulls a container image by name without blocking the UI thread.
--- @param engine table
--- @param image_name string
--- @param on_done fun(ok: boolean, err: string|nil)
--- @return table handle with a `:stop()` method
return function(engine, image_name, on_done)
  return engine.pull_image(image_name, on_done)
end
