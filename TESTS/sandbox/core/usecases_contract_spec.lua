-- The use-case layer is one file per operation, and almost every one of them
-- is a single line: `return engine.<method>(<args in order>)`. That is the
-- whole seam between the command/UI layer and the adapters, which makes it
-- both the cheapest thing in the repo to get wrong and the least likely to be
-- noticed -- a use case that forwards to the wrong method, drops an argument
-- or swaps two of them still loads, still type-checks, and still runs.
--
-- So rather than 57 near-identical spec files, one table: what each use case
-- must call, and with what. Every argument is a distinct sentinel, so a swap
-- fails as loudly as a drop.
--
-- Three further properties are checked over the same table:
--   * it is exhaustive -- a new use-case file that nobody listed here fails
--     the suite instead of quietly going untested;
--   * every method named actually exists on the engine that is supposed to
--     provide it (docker/wsl/compose), which is where a typo would otherwise
--     survive until a user pressed the key;
--   * the value the adapter returns is handed back to the caller unchanged,
--     including the second return value every `(ok, err)` pair depends on.
---@diagnostic disable: need-check-nil

--- @type table<string, { method: string, args: any[], engine: string? }>
local CONTRACT = {
  ["compose.down"] = { method = "down", args = { "file", "on_done" }, engine = "compose" },
  ["compose.logs"] = { method = "logs", args = { "file" }, engine = "compose" },
  ["compose.ps"] = { method = "ps", args = { "file" }, engine = "compose" },
  ["compose.restart"] = { method = "restart", args = { "file", "on_done" }, engine = "compose" },
  ["compose.up"] = { method = "up", args = { "file", "on_done" }, engine = "compose" },

  ["containers.cp_container"] = { method = "cp_container", args = { "src", "dest" } },
  ["containers.exec_in_container"] = { method = "exec_in_container", args = { "id", "shell_cmd", "workdir" } },
  ["containers.get_container_logs"] = { method = "get_logs", args = { "id", "on_done" } },
  ["containers.inspect_container"] = { method = "inspect_container", args = { "id", "on_done" } },
  ["containers.kill_container"] = { method = "kill_container", args = { "id", "on_done" } },
  ["containers.list_containers"] = { method = "list_containers", args = { "on_done", "opts" } },
  ["containers.pause_container"] = { method = "pause_container", args = { "id", "on_done" } },
  ["containers.prune_containers"] = { method = "prune_containers", args = { "on_done" } },
  ["containers.remove_container"] = { method = "remove_container", args = { "id", "on_done" } },
  ["containers.rename_container"] = { method = "rename_container", args = { "id", "new_name" } },
  ["containers.restart_container"] = { method = "restart_container", args = { "id", "on_done" } },
  ["containers.run_container"] = { method = "run_container", args = { "opts", "on_done" } },
  ["containers.start_container"] = { method = "start_container", args = { "id" } },
  ["containers.stats_container"] = { method = "stats_container", args = { "id", "on_done" } },
  ["containers.stop_container"] = { method = "stop_container", args = { "id", "on_done" } },
  ["containers.top_container"] = { method = "top_container", args = { "id", "on_done" } },
  ["containers.unpause_container"] = { method = "unpause_container", args = { "id", "on_done" } },

  ["images.history_image"] = { method = "history_image", args = { "image" } },
  ["images.inspect_image"] = { method = "inspect_image", args = { "image" } },
  ["images.list_images"] = { method = "list_images", args = {} },
  ["images.load_image"] = { method = "load_image", args = { "path" } },
  ["images.prune_images"] = { method = "prune_images", args = { "on_done" } },
  ["images.pull_image"] = { method = "pull_image", args = { "name", "on_done" } },
  ["images.push_image"] = { method = "push_image", args = { "name", "on_done" } },
  ["images.remove_image"] = { method = "remove_image", args = { "id", "on_done" } },
  ["images.save_image"] = { method = "save_image", args = { "image", "path" } },
  ["images.tag_image"] = { method = "tag_image", args = { "source", "target" } },

  ["networks.connect_network"] = { method = "connect_network", args = { "network", "id" } },
  ["networks.create_network"] = { method = "create_network", args = { "name" } },
  ["networks.disconnect_network"] = { method = "disconnect_network", args = { "network", "id" } },
  ["networks.inspect_network"] = { method = "inspect_network", args = { "name" } },
  ["networks.list_networks"] = { method = "list_networks", args = {} },
  ["networks.prune_networks"] = { method = "prune_networks", args = { "on_done" } },
  ["networks.remove_network"] = { method = "remove_network", args = { "name", "on_done" } },

  ["registry.login"] = { method = "login_registry", args = { "username", "password", "registry" } },
  ["registry.logout"] = { method = "logout_registry", args = { "registry" } },

  ["volumes.create_volume"] = { method = "create_volume", args = { "name" } },
  ["volumes.inspect_volume"] = { method = "inspect_volume", args = { "name" } },
  ["volumes.list_volumes"] = { method = "list_volumes", args = {} },
  ["volumes.prune_volumes"] = { method = "prune_volumes", args = { "on_done" } },
  ["volumes.remove_volume"] = { method = "remove_volume", args = { "name", "on_done" } },

  ["wsl.exec_in_distro"] = { method = "exec_in_distro", args = { "name", "command" }, engine = "wsl" },
  ["wsl.export_distro"] = { method = "export_distro", args = { "name", "path" }, engine = "wsl" },
  ["wsl.import_distro"] = {
    method = "import_distro",
    args = { "name", "install_path", "tar_path" },
    engine = "wsl",
  },
  ["wsl.list_distros"] = { method = "list_distros", args = {}, engine = "wsl" },
  ["wsl.set_default_distro"] = { method = "set_default_distro", args = { "name" }, engine = "wsl" },
  ["wsl.set_version_distro"] = { method = "set_version_distro", args = { "name", "version" }, engine = "wsl" },
  ["wsl.shutdown_all"] = { method = "shutdown_all", args = {}, engine = "wsl" },
  ["wsl.start_distro"] = { method = "start_distro", args = { "name" }, engine = "wsl" },
  ["wsl.stop_distro"] = { method = "stop_distro", args = { "name" }, engine = "wsl" },
}

-- `devcontainer.build` is the one use case with logic of its own; it has its
-- own spec next to this one and is not a single delegation.
local NOT_A_DELEGATION = { ["devcontainer.build"] = true }

describe("core.usecases delegation contract", function()
  for key, spec in pairs(CONTRACT) do
    it(key .. " calls engine." .. spec.method .. " with its arguments in order", function()
      local usecase = require("sandbox.core.usecases." .. key)

      local called_with
      local engine = setmetatable({}, {
        __index = function(_, name)
          return function(...)
            called_with = { name = name, args = { ... }, n = select("#", ...) }
            return "RESULT", "SECOND"
          end
        end,
      })

      local sentinels = {}
      for i, arg_name in ipairs(spec.args) do
        sentinels[i] = "<" .. arg_name .. ">"
      end

      local first, second = usecase(engine, unpack(sentinels, 1, #spec.args))

      assert.is_not_nil(called_with, key .. " called nothing on the engine")
      assert.are.equal(spec.method, called_with.name)
      assert.are.same(sentinels, called_with.args)
      assert.are.equal(#spec.args, called_with.n, key .. " forwarded a different number of arguments")
      assert.are.equal("RESULT", first, key .. " swallowed the adapter's return value")
      assert.are.equal("SECOND", second, key .. " swallowed the adapter's second return value")
    end)
  end

  it("lists every use-case file there is", function()
    local files = vim.api.nvim_get_runtime_file("lua/sandbox/core/usecases/**/*.lua", true)
    assert.is_true(#files > 0, "found no use-case files at all -- is the plugin on the runtimepath?")

    local missing = {}
    for _, path in ipairs(files) do
      local normalized = path:gsub("\\", "/")
      local key = normalized:match("lua/sandbox/core/usecases/(.*)%.lua$"):gsub("/", ".")
      if not CONTRACT[key] and not NOT_A_DELEGATION[key] then
        missing[#missing + 1] = key
      end
    end

    assert.are.same({}, missing, "use cases with no entry in this spec's table")
  end)

  it("names only methods the real engines provide", function()
    local providers = {
      container = require("sandbox.adapters.docker.engine"),
      compose = require("sandbox.adapters.docker.compose_engine"),
      wsl = require("sandbox.adapters.wsl.engine"),
    }

    for key, spec in pairs(CONTRACT) do
      local provider = providers[spec.engine or "container"]
      assert.is_function(provider[spec.method], key .. " calls engine." .. spec.method .. ", which does not exist")
    end
  end)
end)
