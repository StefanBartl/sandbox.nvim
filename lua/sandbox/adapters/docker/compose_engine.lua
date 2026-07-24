--[[
  Docker Compose Adapter Aggregator

  Combines compose operations into a full implementation of the
  ComposeEngine port, backed by the `docker compose` CLI plugin.
]]

local up = require("sandbox.adapters.docker.compose.up")
local down = require("sandbox.adapters.docker.compose.down")
local restart = require("sandbox.adapters.docker.compose.restart")
local ps = require("sandbox.adapters.docker.compose.ps")
local logs = require("sandbox.adapters.docker.compose.logs")

return {
  up = up.up,
  down = down.down,
  restart = restart.restart,
  ps = ps.ps,
  logs = logs.logs,
}
