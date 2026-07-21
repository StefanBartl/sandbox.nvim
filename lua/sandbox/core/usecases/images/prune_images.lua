--- Removes all dangling images
--- @param engine table
--- @param on_done? fun(ok: boolean, err: string|nil)
return function(engine, on_done)
  return engine.prune_images(on_done)
end

