local compose_file = require("sandbox.util.compose_file")

--- Run `fn(dir)` in a scratch dir, cleaning it up afterward either way.
---@param fn fun(dir: string): any, any
---@return any, any
local function with_tmpdir(fn)
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, "p")
  local ok, a, b = pcall(fn, dir)
  vim.fn.delete(dir, "rf")
  if not ok then
    error(a, 0)
  end
  return a, b
end

--- Write `text` to a compose.yaml in a scratch dir and read its services.
---@param text string
---@return string[]|nil services, string|nil err
local function services_for(text)
  return with_tmpdir(function(dir)
    local path = dir .. "/compose.yaml"
    vim.fn.writefile(vim.split(text, "\n", { plain = true }), path)
    return compose_file.services(path)
  end)
end

describe("compose_file.services", function()
  it("lists the declared services, sorted", function()
    local services, err = services_for(table.concat({
      "services:",
      "  web:",
      "    image: nginx",
      "  db:",
      "    image: postgres",
    }, "\n"))

    assert.is_nil(err)
    assert.are.same({ "db", "web" }, services)
  end)

  it("does not need a running engine or a valid compose CLI -- it just reads the file", function()
    -- No engine/CLI is faked or stubbed here at all: a pure YAML read.
    local services, err = services_for(table.concat({
      "services:",
      "  only:",
      "    image: alpine",
    }, "\n"))

    assert.is_nil(err)
    assert.are.same({ "only" }, services)
  end)

  it("errors clearly when there is no 'services:' key", function()
    local services, err = services_for("version: '3'\n")

    assert.is_nil(services)
    assert.is_not_nil(err)
    assert.is_not_nil(err and err:find("services", 1, true))
  end)

  it("errors clearly on malformed YAML rather than returning a wrong list", function()
    local services, err = services_for("services:\n  web:\n  bad indentation here")

    assert.is_nil(services)
    assert.is_not_nil(err)
  end)

  it("errors clearly when the file cannot be read", function()
    local services, err = compose_file.services("/no/such/compose.yaml")

    assert.is_nil(services)
    assert.is_not_nil(err)
    assert.is_not_nil(err and err:find("cannot be read", 1, true))
  end)
end)
