--- Regression test for the class of bug fixed in ec213f3 ("merge
--- sub-aggregators wholesale instead of hand-listing fields"): the
--- top-level docker/podman/nerdctl engine.lua aggregators must expose
--- every method their sub-aggregators (containers_engine, images_engine,
--- volumes_engine, networks_engine, registry_engine) define. A hand-copied
--- field list silently drops new methods the moment someone forgets to
--- update it -- every method added to a sub-aggregator this whole session
--- would have been unreachable through sandbox.get_engine() if that bug
--- had still been present.

local function method_names(t)
  local names = {}
  for k, v in pairs(t) do
    if type(v) == "function" then
      names[#names + 1] = k
    end
  end
  table.sort(names)
  return names
end

describe("engine aggregators expose every sub-aggregator method", function()
  local engines = { "docker", "podman", "nerdctl" }
  local sub_aggregators = {
    "containers_engine",
    "images_engine",
    "volumes_engine",
    "networks_engine",
    "registry_engine",
  }

  for _, engine_name in ipairs(engines) do
    it(engine_name .. ".engine.lua reaches every method from its sub-aggregators", function()
      local engine = require("sandbox.adapters." .. engine_name .. ".engine")

      for _, sub_name in ipairs(sub_aggregators) do
        local sub = require("sandbox.adapters." .. engine_name .. "." .. sub_name)
        for _, method in ipairs(method_names(sub)) do
          assert.is_function(
            engine[method],
            engine_name .. ".engine." .. method .. " missing (present in " .. sub_name .. ")"
          )
        end
      end
    end)
  end

  it("docker, podman, and nerdctl expose the exact same method set", function()
    local docker_methods = method_names(require("sandbox.adapters.docker.engine"))
    local podman_methods = method_names(require("sandbox.adapters.podman.engine"))
    local nerdctl_methods = method_names(require("sandbox.adapters.nerdctl.engine"))

    assert.are.same(docker_methods, podman_methods)
    assert.are.same(docker_methods, nerdctl_methods)
  end)
end)
