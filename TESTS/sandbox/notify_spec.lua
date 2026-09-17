-- `notify` and `logger` are the two halves of one decision: the user sees one
-- short line, the diagnostic context goes somewhere it can be read later.
--
-- Both are built at load time from an optional `lib.nvim` (that is the point of
-- the `pcall(require, ...)` at the top of each), so both worlds are exercised
-- here by loading the module with lib.nvim present and again with it made to
-- look absent via `package.preload`.
---@diagnostic disable: need-check-nil

describe("sandbox.logger", function()
  after_each(function()
    package.loaded["sandbox.logger"] = nil
    package.preload["lib.nvim.logger"] = nil
    package.loaded["lib.nvim.logger"] = nil
  end)

  it("uses lib.nvim's logger when it is installed", function()
    local created_with
    package.loaded["lib.nvim.logger"] = {
      new = function(opts)
        created_with = opts
        return {
          trace = function() end,
          debug = function() end,
          info = function() end,
          warn = function() end,
          error = function() end,
        }
      end,
    }
    package.loaded["sandbox.logger"] = nil

    require("sandbox.logger")

    assert.are.equal("sandbox.nvim", created_with.name)
    -- "off", because sandbox.notify owns every user-facing message; a logger
    -- that notified as well would double every warning.
    assert.are.equal("off", created_with.notify_level)
  end)

  it("degrades to a no-op with all five levels when lib.nvim is absent", function()
    package.loaded["lib.nvim.logger"] = nil
    package.preload["lib.nvim.logger"] = function()
      error("module 'lib.nvim.logger' not found")
    end
    package.loaded["sandbox.logger"] = nil

    local logger = require("sandbox.logger")

    for _, level in ipairs({ "trace", "debug", "info", "warn", "error" }) do
      assert.is_function(logger[level], level)
      assert.has_no.errors(function()
        logger[level]("message", { some = "context" })
      end)
    end
  end)
end)

describe("sandbox.notify", function()
  local logged

  --- @param lib_present boolean
  --- @return table notify, table notices
  local function fresh(lib_present)
    local notices = {}
    logged = {}

    package.loaded["sandbox.logger"] = {
      trace = function() end,
      debug = function() end,
      info = function() end,
      warn = function(msg, ctx)
        logged[#logged + 1] = { level = "warn", msg = msg, ctx = ctx }
      end,
      error = function(msg, ctx)
        logged[#logged + 1] = { level = "error", msg = msg, ctx = ctx }
      end,
    }

    package.loaded["lib.nvim.notify"] = nil
    package.preload["lib.nvim.notify"] = nil
    if lib_present then
      package.loaded["lib.nvim.notify"] = {
        create = function(prefix)
          return {
            info = function(msg)
              notices[#notices + 1] = { level = "info", msg = msg, prefix = prefix }
            end,
            warn = function(msg)
              notices[#notices + 1] = { level = "warn", msg = msg, prefix = prefix }
            end,
            error = function(msg)
              notices[#notices + 1] = { level = "error", msg = msg, prefix = prefix }
            end,
          }
        end,
      }
    else
      package.preload["lib.nvim.notify"] = function()
        error("module 'lib.nvim.notify' not found")
      end
    end

    package.loaded["sandbox.notify"] = nil
    return require("sandbox.notify"), notices
  end

  after_each(function()
    package.loaded["sandbox.notify"] = nil
    package.loaded["sandbox.logger"] = nil
    package.loaded["lib.nvim.notify"] = nil
    package.preload["lib.nvim.notify"] = nil
  end)

  it("routes through lib.nvim's factory, prefixed once", function()
    local notify, notices = fresh(true)

    notify.info("started")

    assert.are.equal("[sandbox.nvim]", notices[1].prefix)
    assert.are.equal("started", notices[1].msg)
  end)

  it("records the diagnostic context for warn and error, and shows none of it", function()
    local notify, notices = fresh(true)

    notify.warn("could not parse two rows", { err = "raw CLI text" })
    notify.error("start failed", { id = "abc123", err = "raw CLI text" })

    assert.are.equal("could not parse two rows", notices[1].msg)
    assert.are.equal("start failed", notices[2].msg)
    assert.are.equal("raw CLI text", logged[1].ctx.err)
    assert.are.equal("abc123", logged[2].ctx.id)
  end)

  it("logs nothing for info -- there is no diagnostic context to keep", function()
    local notify = fresh(true)

    notify.info("all good")

    assert.are.same({}, logged)
  end)

  it("falls back to vim.notify with the prefix in the message when lib.nvim is absent", function()
    local notify = fresh(false)
    local seen = {}
    local real_notify = vim.notify
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.notify = function(msg, level)
      seen[#seen + 1] = { msg = msg, level = level }
    end

    notify.info("started")
    notify.warn("careful")
    notify.error("broken")

    vim.notify = real_notify

    assert.are.same({
      { msg = "[sandbox.nvim] started", level = vim.log.levels.INFO },
      { msg = "[sandbox.nvim] careful", level = vim.log.levels.WARN },
      { msg = "[sandbox.nvim] broken", level = vim.log.levels.ERROR },
    }, seen)
    -- The logger half still runs in that world: it is a no-op there, but the
    -- call must not be skipped, or restoring lib.nvim would change behaviour.
    assert.are.equal(2, #logged)
  end)
end)
