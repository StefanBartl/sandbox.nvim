--[[
  Nerdctl Compose Adapter Aggregator

  Combines compose operations into a full implementation of the
  ComposeEngine port, backed by the `nerdctl compose` CLI plugin.
]]

local up = require("sandbox.adapters.nerdctl.compose.up")
local down = require("sandbox.adapters.nerdctl.compose.down")
local restart = require("sandbox.adapters.nerdctl.compose.restart")
local ps = require("sandbox.adapters.nerdctl.compose.ps")
local logs = require("sandbox.adapters.nerdctl.compose.logs")

return {
  up = up.up,
  down = down.down,
  restart = restart.restart,
  ps = ps.ps,
  logs = logs.logs,
}
