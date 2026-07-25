--[[
  Podman Registry Adapter

  Implements registry authentication (login/logout) operations of the
  ContainerEngine port for Podman.
]]

local login = require("sandbox.adapters.podman.registry.login")
local logout = require("sandbox.adapters.podman.registry.logout")

--- Registry operations exposed by the Podman adapter
return {
  login_registry = login.login,
  logout_registry = logout.logout,
}
