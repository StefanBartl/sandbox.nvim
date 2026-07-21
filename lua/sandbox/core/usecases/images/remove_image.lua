--- Removes a container image by ID or name
--- @param engine table
--- @param image_id string
--- @param on_done? fun(ok: boolean, err: string|nil)
return function(engine, image_id, on_done)
  return engine.remove_image(image_id, on_done)
end

