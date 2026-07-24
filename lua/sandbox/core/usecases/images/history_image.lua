-- Use case: Show an image's layer history
--- @param engine table: must implement history_image(image)
--- @param image string
--- @return string[]|nil lines, string|nil err
return function(engine, image)
  return engine.history_image(image)
end
