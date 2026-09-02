---@module 'sandbox.hover'
---@brief What a container image reference under the cursor is, locally.
---@description
--- In a `Dockerfile` or a `compose.yml`, `nginx:1.27-alpine` is a question:
--- is it pulled, how big is it, is anything running from it. All three are
--- answers the engine already has, and reading the file does not give any of
--- them.
---
--- This registers a **position** preview with
--- [hover.nvim](https://github.com/StefanBartl/hover.nvim), and it is
--- `on_request` -- asked only for `:Hover show` or a key bound to it, never
--- on the automatic trigger.
---
--- **That flag is the whole reason this integration exists at all.** Measured
--- end to end against a live docker engine on the machine this was written
--- on, from keypress to rendered float:
---
---     alpine:edge              pulled, no container      754 ms
---     lazyvim_starter:latest   pulled, 1 container       560 ms
---     nginx:1.27-alpine        not pulled                286 ms
---     init.lua:42              declined                    1 ms
---
--- For comparison, hover.nvim reworked its whole bare-path pipeline because a
--- miss there cost 13 ms. Anything in the range above, on a trigger that
--- fires after every keystroke followed by quiet, would be a stutter rather
--- than a feature -- so until hover.nvim grew `on_request` this could not be
--- built honestly.
---
--- The 286 ms line is also why the container listing is a second, conditional
--- call rather than part of one lookup: "not pulled" is the complete answer
--- on its own, and it costs half.
---
--- **The collision worth knowing about**, because it looks like a bug when it
--- shows up: `nginx:1.27` and `init.lua:42` are the same shape, and
--- hover.nvim's bare-path resolver already splits on that colon. Two things
--- keep them apart, and the first does all the work:
---
---   * **A position preview is asked only after every source *and* the
---     bare-path resolver declined.** `init.lua:42` resolves as a file with a
---     line number and never reaches this module.
---   * **The last component of the name must not carry an extension.**
---     `init.lua` does, `nginx` does not, and neither does the `img` in
---     `ghcr.io/user/img`. That mirrors hover.nvim's own rule for deciding
---     when a bare path is unambiguous, and it means a file reference is
---     declined here before any engine is started -- which matters, because
---     starting one is the expensive part.
---
---@see sandbox.core.usecases.images.list_images

local M = {}

local api = vim.api

---@type boolean
local _registered = false

---@internal
--- The `name:tag` the cursor is inside, split, or nil.
---
--- Bounded by the characters an image reference is made of. A digest
--- (`name@sha256:…`) is declined: it is a different lookup and answering the
--- easy half of it would be worse than not answering.
---@param line string
---@param col integer 0-based
---@return string|nil name
---@return string|nil tag
local function image_at(line, col)
  if type(line) ~= "string" or line == "" then
    return nil
  end
  local allowed = "[%w%._%-/:]"
  if not line:sub(col + 1, col + 1):match(allowed) then
    return nil
  end

  local first = col + 1
  while first > 1 and line:sub(first - 1, first - 1):match(allowed) do
    first = first - 1
  end
  local last = col + 1
  while last < #line and line:sub(last + 1, last + 1):match(allowed) do
    last = last + 1
  end

  local run = line:sub(first, last)
  if run:find("@", 1, true) then
    return nil
  end

  local name, tag = run:match("^([%w%._%-/]+):([%w%._%-]+)$")
  if not name or not tag or name == "" or tag == "" then
    return nil
  end

  -- The last component of the name decides whether this is a file reference
  -- wearing an image's shape. `init.lua` carries an extension; `nginx` and
  -- the `img` in `ghcr.io/user/img` do not. A registry host's dots sit in an
  -- earlier component and are untouched by this.
  local leaf = name:match("([^/]+)$") or name
  if leaf:find(".", 1, true) then
    return nil
  end

  return name, tag
end

---@internal
--- The engine's view of `name:tag`, or nil when there is no engine.
---@param name string
---@param tag string
---@return table|nil
local function look_up(name, tag)
  local ok_sandbox, sandbox = pcall(require, "sandbox")
  if not ok_sandbox or type(sandbox.get_engine) ~= "function" then
    return nil
  end
  local ok_engine, engine = pcall(sandbox.get_engine)
  if not ok_engine or type(engine) ~= "table" or type(engine.list_images) ~= "function" then
    return nil
  end

  local ok_list, images = pcall(engine.list_images)
  if not ok_list or type(images) ~= "table" then
    return nil
  end

  local found
  for _, image in ipairs(images) do
    if type(image) == "table" and image.repository == name and image.tag == tag then
      found = image
      break
    end
  end

  -- Containers are a second engine call, so it is only made when the image is
  -- actually here: "not pulled" is the complete answer on its own, and paying
  -- another 200 ms to add nothing to it would be the mistake this whole
  -- module is arranged to avoid.
  local running = {}
  if found and type(engine.list_containers) == "function" then
    local ok_c, containers = pcall(engine.list_containers)
    if ok_c and type(containers) == "table" then
      local reference = name .. ":" .. tag
      for _, container in ipairs(containers) do
        if type(container) == "table" and container.image == reference then
          running[#running + 1] = container
        end
      end
    end
  end

  return { image = found, containers = running }
end

---@internal
--- The float's content.
---@param name string
---@param tag string
---@param result table
---@return table
local function content_for(name, tag, result)
  local reference = name .. ":" .. tag
  if not result.image then
    return {
      lines = { "not pulled", "", "`:Sandbox images pull` fetches it." },
      title = reference,
    }
  end

  local lines = {
    ("pulled  ·  %s"):format(result.image.size or "unknown size"),
  }
  if result.image.id and result.image.id ~= "<no id>" then
    lines[#lines + 1] = ("id      ·  %s"):format(result.image.id)
  end

  if #result.containers == 0 then
    lines[#lines + 1] = ""
    lines[#lines + 1] = "no container from this image"
  else
    lines[#lines + 1] = ""
    lines[#lines + 1] = ("%d container%s:"):format(#result.containers, #result.containers == 1 and "" or "s")
    for _, container in ipairs(result.containers) do
      lines[#lines + 1] = ("  %-10s %s"):format(container.status or "?", container.name or "?")
    end
  end

  return { lines = lines, title = reference }
end

--- Register the position preview with hover.nvim, if it is installed.
---
--- **Declines against a hover.nvim that predates `on_request`.** Registering
--- there would put a 200-to-500 ms engine start on every trigger -- worse
--- than the feature is worth, and a stutter nobody would connect back to
--- here.
---
--- Checked by behaviour rather than by a version or a function name: a
--- registry that simply ignored an unknown key would look identical to one
--- that honours it. So a probe is registered that must *not* be called, the
--- automatic path is exercised once, and the answer is whether it stayed
--- quiet.
---@return boolean registered
function M.setup()
  if _registered then
    return true
  end

  local ok, registry = pcall(require, "hover.registry")
  if not ok or type(registry) ~= "table" or type(registry.register) ~= "function" then
    return false
  end
  if type(registry.position_at) ~= "function" then
    return false
  end
  if not M._supports_on_request(registry) then
    return false
  end

  registry.register("sandbox.nvim", {
    positions = {
      {
        on_request = true,
        ---@param bufnr integer
        ---@param row integer 1-based
        ---@param col integer 0-based
        ---@return table|nil
        fn = function(bufnr, row, col)
          if not api.nvim_buf_is_valid(bufnr) then
            return nil
          end
          local line = api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1]
          local name, tag = image_at(line, col)
          if not name or not tag then
            return nil
          end

          local result = look_up(name, tag)
          if not result then
            return nil
          end
          return content_for(name, tag, result)
        end,
      },
    },
  })

  _registered = true
  return true
end

---@internal
--- Whether this hover.nvim honours `on_request`.
---
--- Asked by behaviour rather than by version: a registry that ignores the
--- flag would consult this module on every `CursorHold`, and the failure
--- would be a stutter nobody connects back to here. Registering a probe that
--- must *not* be called is the only way to know.
---@param registry table
---@return boolean
function M._supports_on_request(registry)
  local called = false
  local ok = pcall(registry.register, "sandbox.nvim.probe", {
    positions = {
      {
        on_request = true,
        fn = function()
          called = true
          return nil
        end,
      },
    },
  })
  if not ok then
    return false
  end

  pcall(registry.position_at, 0, 1, 0)
  -- Registering under the probe's own name and then replacing it with an
  -- empty contribution removes it: hover.nvim keys contributions by plugin
  -- name, so this leaves nothing behind.
  pcall(registry.register, "sandbox.nvim.probe", {})
  return not called
end

--- Whether the position preview is registered with hover.nvim.
---
--- For `:checkhealth sandbox`. There are three separate ways this integration
--- can end up absent -- turned off, hover.nvim missing, hover.nvim too old --
--- and none of them leaves a trace anywhere the user would look.
---@return boolean
function M.registered()
  return _registered
end

---@internal
--- The reference test on its own, for the spec suite.
---@param line string
---@param col integer
---@return string|nil name
---@return string|nil tag
function M.image_at(line, col)
  return image_at(line, col)
end

---@internal
--- Forget the registration. Tests only.
---@return nil
function M._reset()
  _registered = false
end

return M
