--[[
  Nerdctl Registry Adapter

  Implements registry authentication (login/logout) operations of the
  ContainerEngine port for Nerdctl.
]]

local login = require("sandbox.adapters.nerdctl.registry.login")
local logout = require("sandbox.adapters.nerdctl.registry.logout")

--- Registry operations exposed by the Nerdctl adapter
return {
  login_registry = login.login,
  logout_registry = logout.logout,
}
