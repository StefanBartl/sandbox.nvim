-- Use case: Save (export) an image to a tarball on disk
--- @param engine table: must implement save_image(image, path)
--- @param image string
--- @param path string
--- @return boolean ok, string|nil err
return function(engine, image, path)
  return engine.save_image(image, path)
end
