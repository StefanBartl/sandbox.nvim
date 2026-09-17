-- `compose_file.find` -- the upward search that decides which project every
-- `:Sandbox compose …` subcommand acts on. It is resolved fresh on each call,
-- so moving the cwd changes the project, which is exactly why it is worth
-- pinning: a wrong answer here points `compose down` at someone else's file.
--
-- Fixtures live under `vim.fn.tempname()` and are deleted afterwards; nothing
-- writes inside the repo. The cwd is moved for the duration and restored --
-- `find` reads `vim.fn.getcwd()` and there is no way to ask it about another
-- directory.
---@diagnostic disable: need-check-nil

local compose_file = require("sandbox.util.compose_file")

--- Run `fn(dir)` with the cwd inside a fresh scratch directory.
--- @param fn fun(dir: string): any
--- @return any
local function in_tmpdir(fn)
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, "p")
  local previous = vim.fn.getcwd()
  local ok, result = pcall(function()
    -- `tempname()` can hand back a path Vim would read as having wildcards;
    -- escape it rather than hope.
    vim.cmd("cd " .. vim.fn.fnameescape(dir))
    return fn(dir)
  end)
  vim.cmd("cd " .. vim.fn.fnameescape(previous))
  vim.fn.delete(dir, "rf")
  if not ok then
    error(result, 0)
  end
  return result
end

--- @param path string
local function touch(path)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  vim.fn.writefile({ "services:", "  app:", "    image: alpine" }, path)
end

describe("compose_file.find", function()
  it("finds nothing in an empty directory", function()
    in_tmpdir(function()
      assert.is_nil(compose_file.find())
    end)
  end)

  local NAMES = {
    "docker-compose.yml",
    "docker-compose.yaml",
    "compose.yml",
    "compose.yaml",
    "podman-compose.yml",
    "podman-compose.yaml",
  }

  for _, name in ipairs(NAMES) do
    it("recognises " .. name, function()
      in_tmpdir(function(dir)
        touch(dir .. "/" .. name)

        local found = compose_file.find()

        assert.is_not_nil(found, name)
        assert.is_truthy(found:gsub("\\", "/"):find(name, 1, true), found)
      end)
    end)
  end

  it("searches upward, so a subdirectory finds the project's file", function()
    in_tmpdir(function(dir)
      touch(dir .. "/compose.yml")
      vim.fn.mkdir(dir .. "/src/deep", "p")
      vim.cmd("cd " .. vim.fn.fnameescape(dir .. "/src/deep"))

      local found = compose_file.find()

      assert.is_not_nil(found)
      assert.is_truthy(found:gsub("\\", "/"):find("compose.yml", 1, true))
    end)
  end)

  it("prefers the nearest file over the one further up", function()
    in_tmpdir(function(dir)
      touch(dir .. "/compose.yml")
      touch(dir .. "/sub/compose.yml")
      vim.cmd("cd " .. vim.fn.fnameescape(dir .. "/sub"))

      local found = (compose_file.find() or ""):gsub("\\", "/")

      assert.is_truthy(found:find("/sub/compose.yml", 1, true), found)
    end)
  end)

  it("does not look sideways into a sibling directory", function()
    in_tmpdir(function(dir)
      touch(dir .. "/other/compose.yml")
      vim.fn.mkdir(dir .. "/here", "p")
      vim.cmd("cd " .. vim.fn.fnameescape(dir .. "/here"))

      -- Whatever it finds must not be the sibling's file. (A file further up
      -- the real filesystem is possible on a machine that happens to have one,
      -- so the assertion is on the sibling, not on nil.)
      local found = (compose_file.find() or ""):gsub("\\", "/")

      assert.is_falsy(found:find("/other/compose.yml", 1, true), found)
    end)
  end)

  it("hands a path the services reader can actually open", function()
    in_tmpdir(function(dir)
      touch(dir .. "/compose.yaml")

      local found = compose_file.find()
      local services, err = compose_file.services(found)

      assert.is_nil(err)
      assert.are.same({ "app" }, services)
    end)
  end)
end)
