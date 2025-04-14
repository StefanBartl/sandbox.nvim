-- Use case: Prune all stopped containers
--- @param engine table: must implement prune_containers
return function(engine)
  return engine.prune_containers()
end
