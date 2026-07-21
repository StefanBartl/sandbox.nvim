-- Use case: Execute a ahell in container
--- @param engine table: must implement exec_in_container(container_id, shell_cmd)
--- @param container_id string
--- @param shell_cmd string[]: shell command to run (e.g. { "sh" })
return function(engine, container_id, shell_cmd)
  return engine.exec_in_container(container_id, shell_cmd)
end
