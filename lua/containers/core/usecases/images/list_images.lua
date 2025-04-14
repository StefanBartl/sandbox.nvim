--- Lists all images available locally
--- @param engine table: must implement list_images()
return function(engine)
  return engine.list_images()
end

