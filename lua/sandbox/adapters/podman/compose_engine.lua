--[[
  Podman Compose Adapter Aggregator

  Combines compose operations into a full implementation of the
  ComposeEngine port, backed by the `podman compose` CLI.
]]

local up = require("sandbox.adapters.podman.compose.up")
local down = require("sandbox.adapters.podman.compose.down")
local restart = require("sandbox.adapters.podman.compose.restart")
local ps = require("sandbox.adapters.podman.compose.ps")
local logs = require("sandbox.adapters.podman.compose.logs")

return {
  up = up.up,
  down = down.down,
  restart = restart.restart,
  ps = ps.ps,
  logs = logs.logs,
}
