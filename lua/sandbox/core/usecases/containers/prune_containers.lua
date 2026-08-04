---@module 'sandbox.core.usecases.containers.prune_containers'
--- Use case: Prune all stopped containers
--- @param engine table: must implement prune_containers(on_done)
--- @param on_done? fun(ok: boolean, err: string|nil)
return function(engine, on_done)
  return engine.prune_containers(on_done)
end
