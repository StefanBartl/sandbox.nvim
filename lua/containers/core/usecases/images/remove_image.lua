--- Removes a container image by ID or name
--- @param engine table
--- @param image_id string
return function(engine, image_id)
  return engine.remove_image(image_id)
end

