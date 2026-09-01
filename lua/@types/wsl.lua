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
---@field set_default_distro fun(name: string): boolean, string|nil
---@field set_version_distro fun(name: string, version: integer): boolean, string|nil
---@field export_distro fun(name: string, path: string): boolean, string|nil
---@field import_distro fun(name: string, install_path: string, tar_path: string): boolean, string|nil
---@field shutdown_all fun(): boolean, string|nil
