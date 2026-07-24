-- Use Case: Inspect detailed metadata of an image
--- @param engine table: must implement inspect_image(image)
--- @param image string
--- @return table|string[]
return function(engine, image)
  return engine.inspect_image(image)
end
