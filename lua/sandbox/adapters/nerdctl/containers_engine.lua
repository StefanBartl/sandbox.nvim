--[[
  Nerdctl Container Adapter

  Implements container-related operations of the ContainerEngine port
  for Nerdctl: list, start, stop, exec, inspect, remove, prune, etc.
]]

local list_containers = require("sandbox.adapters.nerdctl.containers.list_containers")
local get_logs = require("sandbox.adapters.nerdctl.containers.get_logs")
local follow_logs = require("sandbox.adapters.nerdctl.containers.follow_logs")
local exec_in_container = require("sandbox.adapters.nerdctl.containers.exec_in_container")
local start = require("sandbox.adapters.nerdctl.containers.start_container")
local stop = require("sandbox.adapters.nerdctl.containers.stop_container")
local kill_container = require("sandbox.adapters.nerdctl.containers.kill_container")
local restart_container = require("sandbox.adapters.nerdctl.containers.restart_container")
local pause_container = require("sandbox.adapters.nerdctl.containers.pause_container")
local rename_container = require("sandbox.adapters.nerdctl.containers.rename_container")
local stats_container = require("sandbox.adapters.nerdctl.containers.stats_container")
local top_container = require("sandbox.adapters.nerdctl.containers.top_container")
local cp_container = require("sandbox.adapters.nerdctl.containers.cp_container")
local run_container = require("sandbox.adapters.nerdctl.containers.run_container")
local remove_container = require("sandbox.adapters.nerdctl.containers.remove_container")
local inspect_container = require("sandbox.adapters.nerdctl.containers.inspect_container")
local prune_containers = require("sandbox.adapters.nerdctl.containers.prune_containers")

--- Container operations exposed by the Nerdctl adapter
return {
  list_containers = list_containers.list_containers,
  get_logs = get_logs.get_logs,
  follow_logs = follow_logs.follow_logs,
  exec_in_container = exec_in_container.exec_in_container,
  start_container = start.start_container,
  stop_container = stop.stop_container,
  kill_container = kill_container.kill_container,
  restart_container = restart_container.restart_container,
  pause_container = pause_container.pause_container,
  unpause_container = pause_container.unpause_container,
  rename_container = rename_container.rename_container,
  stats_container = stats_container.stats_container,
  top_container = top_container.top_container,
  cp_container = cp_container.cp_container,
  run_container = run_container.run_container,
  remove_container = remove_container.remove_container,
  inspect_container = inspect_container.inspect_container,
  prune_containers = prune_containers.prune_containers,
}
