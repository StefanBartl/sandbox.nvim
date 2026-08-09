describe("bindings.usrcmds.container_commands.run", function()
  local queue

  before_each(function()
    package.loaded["sandbox"] = {
      get_engine = function()
        return "docker"
      end,
    }
    -- Mirrors kit.form's real step-through-fields/required-abort contract
    -- (lib.nvim's lua/lib/nvim/ui/kit/form.lua) so these specs exercise the
    -- same field-order/cancel semantics container_commands.lua relies on.
    package.loaded["lib.nvim.ui.kit"] = {
      form = function(opts)
        local fields = opts.fields or {}
        local values = {}
        local function step(i)
          local field = fields[i]
          if not field then
            if opts.on_submit then
              opts.on_submit(values)
            end
            return
          end
          local item = table.remove(queue, 1)
          if item.cancel then
            if field.required then
              if opts.on_cancel then
                opts.on_cancel()
              end
              return
            end
            values[field.name] = field.default or ""
          else
            values[field.name] = item.value
          end
          step(i + 1)
        end
        step(1)
      end,
    }
    package.loaded["sandbox.bindings.usrcmds.container_commands"] = nil
  end)

  after_each(function()
    package.loaded["lib.nvim.ui.kit"] = nil
    package.loaded["sandbox.core.usecases.containers.run_container"] = nil
    package.loaded["sandbox.bindings.usrcmds.container_commands"] = nil
  end)

  it("runs with all fields submitted", function()
    local captured_opts
    package.loaded["sandbox.core.usecases.containers.run_container"] = function(_engine, opts, cb)
      captured_opts = opts
      cb(true, "abc123")
    end
    local cc = require("sandbox.bindings.usrcmds.container_commands")

    queue = {
      { value = "alpine:latest" },
      { value = "myctr" },
      { value = "8080:80" },
      { value = "/host:/container" },
      { value = "FOO=bar" },
    }
    cc.run()

    assert.are.equal("alpine:latest", captured_opts.image)
    assert.are.equal("myctr", captured_opts.name)
    assert.are.same({ "8080:80" }, captured_opts.ports)
    assert.are.same({ "/host:/container" }, captured_opts.volumes)
    assert.are.same({ "FOO=bar" }, captured_opts.env)
  end)

  it("<Esc> on an optional field behaves like an empty submit, not an abort", function()
    local captured_opts
    package.loaded["sandbox.core.usecases.containers.run_container"] = function(_engine, opts, cb)
      captured_opts = opts
      cb(true, "abc123")
    end
    local cc = require("sandbox.bindings.usrcmds.container_commands")

    queue = {
      { value = "alpine:latest" },
      { cancel = true },
      { cancel = true },
      { cancel = true },
      { cancel = true },
    }
    cc.run()

    assert.is_not_nil(captured_opts)
    assert.are.equal("alpine:latest", captured_opts.image)
    assert.is_nil(captured_opts.name)
    assert.is_nil(captured_opts.ports)
  end)

  it("<Esc> on the required Image field aborts without running", function()
    local ran = false
    package.loaded["sandbox.core.usecases.containers.run_container"] = function(_engine, _opts, cb)
      ran = true
      cb(true, "abc123")
    end
    local cc = require("sandbox.bindings.usrcmds.container_commands")

    queue = { { cancel = true } }
    cc.run()

    assert.is_false(ran)
  end)
end)
