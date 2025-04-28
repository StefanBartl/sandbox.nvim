--[[
  Docker Container Adapter

  Implements container-related operations of the ContainerEngine port
  for Docker: list, start, stop, exec, inspect, remove, prune, etc.
]]

local list_containers = require("containers.adapters.docker.containers.list_containers")
local get_logs = require("containers.adapters.docker.containers.get_logs")
local exec_in_container = require("containers.adapters.docker.containers.exec_in_container")
local start = require("containers.adapters.docker.containers.start_container")
local stop = require("containers.adapters.docker.containers.stop_container")
local kill_container = require("containers.adapters.docker.containers.kill_container")
local remove_container = require("containers.adapters.docker.containers.remove_container")
local inspect_container = require("containers.adapters.docker.containers.inspect_container")
local prune_containers = require("containers.adapters.docker.containers.prune_containers")

--- Container operations exposed by the Docker adapter
return {
  list_containers = list_containers.list_containers,
  get_logs = get_logs.get_logs,
  exec_in_container = exec_in_container.exec_in_container,
  start_container = start.start_container,
  stop_container = stop.stop_container,
  kill_container = kill_container.kill_container,
  remove_container = remove_container.remove_container,
  inspect_container = inspect_container.inspect_container,
  prune_containers = prune_containers.prune_containers,
}
