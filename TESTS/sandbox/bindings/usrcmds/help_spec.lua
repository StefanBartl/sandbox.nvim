-- Every flag, key=value pair and positional argument of `:Sandbox` / `:Sbx` has a line in lib.nvim's
-- option float.
--
-- The text comes from the `desc` of each FlagSpec/KvSpec/ArgSpec in `sandbox.bindings.usrcmds` (the
-- shared `--buffer` flag, the `workdir=` pair of the exec routes, `desc`/`enum_desc` on an argument)
-- or from the `desc` of a custom argument type (CONTAINER_ID, IMAGE_ID, ...), written once per type.
-- A new option or argument without one shows up as a bare row in the cheatsheet, so this fails until
-- it is described. Runs against the real composer and the real route table; nothing reaches an
-- engine because registering only builds the verb.
--
-- `setup()` only builds the nine `wsl` routes where wsl.exe is reachable. This spec must not depend on
-- the host, or a wsl option added later without a text (or with a bad one) would stay green on every
-- machine without wsl.exe (the ubuntu/macos CI legs, any Linux dev box): `setup_with_wsl()` pretends
-- wsl.exe exists for the duration of `setup()` and the spec asserts that the wsl namespace was walked.
---@diagnostic disable: undefined-field -- luassert extends `assert` beyond stock Lua's.

--- Run `sandbox.bindings.usrcmds.setup()` as if wsl.exe were reachable, then restore the real probe.
--- The module is reloaded first so that its `wsl_commands` upvalue is the very table patched here, and
--- whatever an earlier spec left in `package.loaded` cannot make the stub miss.
local function setup_with_wsl()
  package.loaded["sandbox.bindings.usrcmds"] = nil
  local wsl = require("sandbox.bindings.usrcmds.wsl_commands")
  local real_available = wsl.available
  wsl.available = function()
    return true
  end

  local ok, err = pcall(function()
    require("sandbox.bindings.usrcmds").setup()
  end)

  wsl.available = real_available
  assert(ok, err)
end

--- The number of `wsl <verb>` routes of a registered verb.
---@param handle table
---@return integer
local function count_wsl_routes(handle)
  local n = 0
  for _, route in ipairs(handle:spec().routes or {}) do
    if route.path[1] == "wsl" then
      n = n + 1
    end
  end
  return n
end

describe("bindings.usrcmds option float", function()
  after_each(function()
    pcall(vim.api.nvim_del_user_command, "Sandbox")
    pcall(vim.api.nvim_del_user_command, "Sbx")
  end)

  it("describes every flag, key=value pair and positional argument of :Sandbox and :Sbx", function()
    local composer = require("lib.nvim.bindings.usercmd.composer")

    -- A lib.nvim older than `help.undocumented` cannot answer the question; that is a missing
    -- feature of the dependency, not a defect of this plugin.
    if type(composer.help.undocumented) ~= "function" then
      return
    end

    setup_with_wsl()

    for _, name in ipairs({ "Sandbox", "Sbx" }) do
      assert.is_not_nil(composer.registry()[name], ":" .. name .. " is registered through the composer")
      assert.is_true(
        count_wsl_routes(composer.registry()[name]) > 0,
        ":" .. name .. " includes the wsl routes whatever host this runs on"
      )

      local missing = {}
      for _, m in ipairs(composer.help.undocumented(name, { args = true })) do
        missing[#missing + 1] = ("%s %s"):format(m.route, m.name)
      end
      assert.equals(0, #missing, ":" .. name .. " options without a help text: " .. table.concat(missing, ", "))
    end
  end)

  it("keeps every argument text to one short line without a trailing full stop", function()
    local composer = require("lib.nvim.bindings.usercmd.composer")
    local ok, argtypes = pcall(require, "lib.nvim.bindings.usercmd.composer.argtypes")

    -- Same guard as above: the float's argument rows need a lib.nvim that knows `desc` on a type.
    if not (ok and type(composer.help.undocumented) == "function") then
      return
    end

    setup_with_wsl()

    local handle = composer.registry().Sandbox
    assert.is_truthy(handle)
    assert.is_true(count_wsl_routes(handle) > 0, "the wsl routes are walked whatever host this runs on")

    -- Every text an argument can bring: its own `desc`, the `desc` of its type, its `enum_desc` values.
    local seen = 0
    local function check(text, what)
      seen = seen + 1
      assert.is_string(text, what .. " is a string")
      assert.is_true(text ~= "", what .. " shows a text")
      assert.is_nil(text:find("\n", 1, true), what .. " is one line")
      assert.is_true(#text <= 80, what .. " stays short")
      assert.is_nil(text:find("%.$"), what .. " has no trailing full stop")
    end

    for _, route in ipairs(handle:spec().routes or {}) do
      local path = table.concat(route.path, " ")
      for _, arg in ipairs(route.args or {}) do
        local what = ("argument %s of %s"):format(arg.name, path)
        if arg.desc then
          check(arg.desc, what)
        end
        local def = arg.type and argtypes.get(arg.type)
        if def and def.desc then
          check(def.desc, ("type %s of %s"):format(arg.type, what))
        end
        for value, text in pairs(arg.enum_desc or {}) do
          check(text, ("value %s of %s"):format(value, what))
        end
      end
    end
    assert.is_true(seen > 0, "the routes' arguments were actually walked")
  end)
end)
