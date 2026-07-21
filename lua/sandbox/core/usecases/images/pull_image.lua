--- Pulls a container image by name
--- @param engine table
--- @param image_name string
--- @return boolean ok, string|nil err
return function(engine, image_name)
  return engine.pull_image(image_name)
end

