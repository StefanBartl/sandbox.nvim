---@module '@types.wsl'

---@class WslDistro
---@field name string
---@field state "Running"|"Stopped"|string
---@field default boolean

---@class WslEngine
---@field list_distros fun(): WslDistro[]
---@field start_distro fun(name: string): boolean
---@field stop_distro fun(name: string): boolean
---@field exec_in_distro fun(name: string, command: string[]|nil): nil

