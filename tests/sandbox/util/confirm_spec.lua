describe("util.confirm", function()
  local fake_kit

  before_each(function()
    fake_kit = {
      confirm = function(opts)
        fake_kit.last_opts = opts
      end,
    }
    package.loaded["lib.nvim.ui.kit"] = fake_kit
    package.loaded["sandbox.util.confirm"] = nil
    package.loaded["sandbox.config"] = nil
  end)

  after_each(function()
    package.loaded["lib.nvim.ui.kit"] = nil
  end)

  it("routes through kit.confirm with the given question", function()
    local config = require("sandbox.config")
    config.options.confirm_destructive = true

    local M = require("sandbox.util.confirm")
    local ran = false
    M.destructive("Delete container foo?", function()
      ran = true
    end)

    assert.are.equal("Delete container foo?", fake_kit.last_opts.question)
    assert.is_false(ran)

    fake_kit.last_opts.on_answer(true)
    assert.is_true(ran)
  end)

  it("does not run on_confirm when answer is No", function()
    local config = require("sandbox.config")
    config.options.confirm_destructive = true

    local M = require("sandbox.util.confirm")
    local ran = false
    M.destructive("Delete container foo?", function()
      ran = true
    end)

    fake_kit.last_opts.on_answer(false)
    assert.is_false(ran)
  end)

  it("skips the prompt entirely when confirm_destructive is false", function()
    local config = require("sandbox.config")
    config.options.confirm_destructive = false

    local M = require("sandbox.util.confirm")
    local ran = false
    M.destructive("Delete container foo?", function()
      ran = true
    end)

    assert.is_true(ran)
    assert.is_nil(fake_kit.last_opts)
  end)
end)
