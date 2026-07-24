-- Use case: Tag a local image
--- @param engine table: must implement tag_image(source, target)
--- @param source string
--- @param target string
--- @return boolean ok, string|nil err
return function(engine, source, target)
  return engine.tag_image(source, target)
end
