--[[
  Docker Registry Adapter

  Implements registry authentication (login/logout) operations of the
  ContainerEngine port for Docker.
]]

local login = require("sandbox.adapters.docker.registry.login")
local logout = require("sandbox.adapters.docker.registry.logout")

--- Registry operations exposed by the Docker adapter
return {
  login_registry = login.login,
  logout_registry = logout.logout,
}
