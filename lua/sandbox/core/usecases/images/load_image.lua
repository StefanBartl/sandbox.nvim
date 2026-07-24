-- Use case: Load (import) an image from a tarball on disk
--- @param engine table: must implement load_image(path)
--- @param path string
--- @return boolean ok, string|nil err
return function(engine, path)
  return engine.load_image(path)
end
