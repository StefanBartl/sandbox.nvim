-- Use case: Create and start a new container
--- @param engine table: must implement run_container(opts, on_done)
--- @param opts Sandbox.RunOpts
--- @param on_done? fun(ok: boolean, result: string|nil)
return function(engine, opts, on_done)
  return engine.run_container(opts, on_done)
end
