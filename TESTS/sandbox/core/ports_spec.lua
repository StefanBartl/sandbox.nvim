-- `core/ports/` is the interface, written as a table of functions that all
-- raise. Two things about it are worth a test rather than a reading:
--
--   1. Every port method is implemented by the adapters that claim to be that
--      port. A method added to a port and to nothing else is not a compile
--      error in Lua; it is a `nil` at the call site, months later.
--   2. A port stub that is reached anyway has to raise, and the message has to
--      name the method. `statusline.lua` and `container_commands.inspect`
--      both wrap their calls in `pcall` specifically because these raise, so
--      that is behaviour, not decoration.
--
-- The three adapters' *engines* are the implementations under test; nothing is
-- spawned, because nothing is called.
---@diagnostic disable: need-check-nil

--- @param t table
--- @return string[]
local function method_names(t)
  local names = {}
  for name, value in pairs(t) do
    if type(value) == "function" then
      names[#names + 1] = name
    end
  end
  table.sort(names)
  return names
end

describe("core.ports", function()
  local CASES = {
    {
      port = "sandbox.core.ports.container_engine",
      implementations = {
        "sandbox.adapters.docker.engine",
        "sandbox.adapters.podman.engine",
        "sandbox.adapters.nerdctl.engine",
      },
    },
    {
      port = "sandbox.core.ports.compose_engine",
      implementations = {
        "sandbox.adapters.docker.compose_engine",
        "sandbox.adapters.podman.compose_engine",
        "sandbox.adapters.nerdctl.compose_engine",
      },
    },
    {
      port = "sandbox.core.ports.wsl_engine",
      implementations = { "sandbox.adapters.wsl.engine" },
    },
  }

  for _, case in ipairs(CASES) do
    local port_name = case.port:match("[^.]+$")

    it(port_name .. " declares nothing but functions", function()
      local port = require(case.port)
      local declared = method_names(port)

      assert.is_true(#declared > 0, port_name .. " declares no methods at all")
      for key in pairs(port) do
        assert.is_function(port[key], port_name .. "." .. tostring(key) .. " is not a function")
      end
    end)

    for _, impl_name in ipairs(case.implementations) do
      it(impl_name:match("adapters%.(.*)") .. " implements every " .. port_name .. " method", function()
        local port = require(case.port)
        local impl = require(impl_name)

        local missing = {}
        for _, method in ipairs(method_names(port)) do
          if type(impl[method]) ~= "function" then
            missing[#missing + 1] = method
          end
        end

        assert.are.same({}, missing, impl_name .. " is missing port methods")
      end)
    end

    it(port_name .. "'s own stubs raise, naming the method", function()
      local port = require(case.port)

      for _, method in ipairs(method_names(port)) do
        -- Called with string arguments throughout: most stubs concatenate one
        -- of them into the message, which is the whole reason they take it (and
        -- a non-string there would raise a concat error instead, hiding the
        -- name the assertion below is looking for).
        local ok, err = pcall(port[method], "some-id", "another-id", "a-third")

        assert.is_false(ok, port_name .. "." .. method .. " did not raise")
        assert.is_truthy(
          tostring(err):find(method .. " not implemented", 1, true),
          port_name .. "." .. method .. " raised without naming itself: " .. tostring(err)
        )
      end
    end)
  end

  it("the container port and the container adapters agree exactly, in both directions", function()
    -- A method on the adapters that the port never declared is the other half
    -- of the same drift: it works, and it is invisible to anybody reading the
    -- interface.
    local port = method_names(require("sandbox.core.ports.container_engine"))
    local docker = method_names(require("sandbox.adapters.docker.engine"))

    assert.are.same(port, docker)
  end)
end)
