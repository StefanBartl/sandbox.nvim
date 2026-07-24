-- Use case: Copy a file or directory between the host and a container
--- @param engine table: must implement cp_container(src, dest)
--- @param src string
--- @param dest string
--- @return boolean ok, string|nil err
return function(engine, src, dest)
  return engine.cp_container(src, dest)
end
