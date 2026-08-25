local devcontainer_file = require("sandbox.util.devcontainer_file")

--- Run `fn(dir)` in a scratch dir, cleaning it up afterward either way.
--- `fn` is assumed to return at most 2 values -- a plain `{pcall(fn, dir)}`
--- table plus `unpack(t, 2)` would be unreliable here since `#t` is
--- ambiguous once a two-value `(nil, "err")` return leaves a nil hole.
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

--- Write `text` to a devcontainer.json in a scratch dir and parse it.
---@param text string
---@return table|nil config, string|nil err
local function parse_text(text)
  return with_tmpdir(function(dir)
    local path = dir .. "/devcontainer.json"
    vim.fn.writefile(vim.split(text, "\n", { plain = true }), path)
    return devcontainer_file.parse(path)
  end)
end

describe("devcontainer_file.find", function()
  it("finds .devcontainer/devcontainer.json (vim.fs.find upward doesn't recurse into subdirs)", function()
    with_tmpdir(function(dir)
      vim.fn.mkdir(dir .. "/.devcontainer", "p")
      vim.fn.writefile({ "{}" }, dir .. "/.devcontainer/devcontainer.json")

      local orig = vim.fn.getcwd()
      vim.cmd("cd " .. vim.fn.fnameescape(dir))
      local found = devcontainer_file.find()
      vim.cmd("cd " .. vim.fn.fnameescape(orig))

      assert.is_not_nil(found)
      assert.is_not_nil(found and found:find("devcontainer.json", 1, true))
    end)
  end)

  it("falls back to the flat .devcontainer.json", function()
    with_tmpdir(function(dir)
      vim.fn.writefile({ "{}" }, dir .. "/.devcontainer.json")

      local orig = vim.fn.getcwd()
      vim.cmd("cd " .. vim.fn.fnameescape(dir))
      local found = devcontainer_file.find()
      vim.cmd("cd " .. vim.fn.fnameescape(orig))

      assert.is_not_nil(found)
      assert.is_not_nil(found and found:find(".devcontainer.json", 1, true))
    end)
  end)

  it("returns nil when nothing is found", function()
    with_tmpdir(function(dir)
      local orig = vim.fn.getcwd()
      vim.cmd("cd " .. vim.fn.fnameescape(dir))
      local found = devcontainer_file.find()
      vim.cmd("cd " .. vim.fn.fnameescape(orig))

      assert.is_nil(found)
    end)
  end)

  it("prefers the nested form over the flat form", function()
    with_tmpdir(function(dir)
      vim.fn.mkdir(dir .. "/.devcontainer", "p")
      vim.fn.writefile({ '{"name":"nested"}' }, dir .. "/.devcontainer/devcontainer.json")
      vim.fn.writefile({ '{"name":"flat"}' }, dir .. "/.devcontainer.json")

      local orig = vim.fn.getcwd()
      vim.cmd("cd " .. vim.fn.fnameescape(dir))
      local found = devcontainer_file.find()
      vim.cmd("cd " .. vim.fn.fnameescape(orig))

      assert.is_not_nil(found)
      local config = found and devcontainer_file.parse(found)
      assert.are.equal("nested", config and config.name)
    end)
  end)
end)

describe("devcontainer_file.workspace_dir", function()
  it("strips .devcontainer/devcontainer.json down to the project root", function()
    assert.are.equal("/proj", devcontainer_file.workspace_dir("/proj/.devcontainer/devcontainer.json"))
  end)

  it("strips .devcontainer.json down to the project root", function()
    assert.are.equal("/proj", devcontainer_file.workspace_dir("/proj/.devcontainer.json"))
  end)
end)

describe("devcontainer_file.parse (JSONC)", function()
  it("decodes plain JSON", function()
    local config, err = parse_text('{"image":"ubuntu"}')

    assert.is_nil(err)
    assert.are.equal("ubuntu", config and config.image)
  end)

  it("strips // line comments", function()
    local config, err = parse_text(table.concat({
      "{",
      "  // a comment",
      '  "image": "ubuntu"',
      "}",
    }, "\n"))

    assert.is_nil(err)
    assert.are.equal("ubuntu", config and config.image)
  end)

  it("strips /* */ block comments", function()
    local config, err = parse_text('{ /* block comment */ "image": "ubuntu" }')

    assert.is_nil(err)
    assert.are.equal("ubuntu", config and config.image)
  end)

  it("does not strip // or /* inside string values", function()
    local config, err = parse_text('{"image":"registry.example.com/foo//bar:latest"}')

    assert.is_nil(err)
    assert.are.equal("registry.example.com/foo//bar:latest", config and config.image)
  end)

  it("strips a trailing comma before } or ]", function()
    local config, err = parse_text('{ "forwardPorts": [3000, 8080,], "image": "ubuntu", }')

    assert.is_nil(err)
    assert.are.same({ 3000, 8080 }, config and config.forwardPorts)
  end)

  it("returns an error for genuinely malformed JSON", function()
    local config, err = parse_text("{ not json")

    assert.is_nil(config)
    assert.is_not_nil(err)
  end)
end)
