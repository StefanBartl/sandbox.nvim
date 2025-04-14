--- Removes all dangling images
--- @param engine table
return function(engine)
  return engine.prune_images()
end

