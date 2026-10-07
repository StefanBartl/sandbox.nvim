-- Every flag and key=value pair of `:Sandbox` / `:Sbx` has a line in lib.nvim's option float.
--
-- The text comes from the `desc` of each FlagSpec/KvSpec in `sandbox.bindings.usrcmds` (the shared
-- `--buffer` flag and the `workdir=` pair of the exec routes). A new option without one shows up as
-- a bare row in the cheatsheet, so this fails until it is described. Runs against the real composer
-- and the real route table; nothing reaches an engine because registering only builds the verb.
---@diagnostic disable: undefined-field -- luassert extends `assert` beyond stock Lua's.

describe("bindings.usrcmds option float", function()
  after_each(function()
    pcall(vim.api.nvim_del_user_command, "Sandbox")
    pcall(vim.api.nvim_del_user_command, "Sbx")
  end)

  it("describes every flag and key=value pair of :Sandbox and :Sbx", function()
    local composer = require("lib.nvim.bindings.usercmd.composer")

    -- A lib.nvim older than `help.undocumented` cannot answer the question; that is a missing
    -- feature of the dependency, not a defect of this plugin.
    if type(composer.help.undocumented) ~= "function" then
      return
    end

    require("sandbox.bindings.usrcmds").setup()

    for _, name in ipairs({ "Sandbox", "Sbx" }) do
      assert.is_not_nil(composer.registry()[name], ":" .. name .. " is registered through the composer")

      local missing = {}
      for _, m in ipairs(composer.help.undocumented(name)) do
        missing[#missing + 1] = ("%s %s"):format(m.route, m.name)
      end
      assert.equals(0, #missing, ":" .. name .. " options without a help text: " .. table.concat(missing, ", "))
    end
  end)
end)
