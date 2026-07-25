---@module 'sandbox.telescope.images'
--- Fuzzy-pick an image and act on it. Docker/nerdctl's list_images output is
--- normalized ({id, repository, tag, size}); Podman's is the raw
--- `podman images --format json` shape ({Id, Names, Size}) -- same split
--- image_commands.list() already handles when picking a list view.

return function()
  local notify = require("sandbox.notify")
  local sandbox = require("sandbox")
  local engine = sandbox.get_engine()
  if not engine then
    return
  end

  local usecase = require("sandbox.core.usecases.images.list_images")
  local images, err = usecase(engine)
  if not images then
    notify.error("Failed to list images: " .. tostring(err), { err = err })
    return
  end

  local image_cmds = require("sandbox.bindings.usrcmds.image_commands")
  -- Match the same engine get_engine() actually resolved to (session
  -- override/.sandboxrc/config), not just the static config value.
  local is_podman = sandbox.resolve_engine_name() == "podman"

  ---@param img table
  ---@return string display, string ref
  local function describe(img)
    if is_podman then
      local name = (img.Names or {})[1] or "<none>:<none>"
      local repo, tag = name:match("^(.-):([^:]+)$")
      repo, tag = repo or "<none>", tag or "<none>"
      local id = (img.Id or ""):sub(1, 12)
      local ref = (repo ~= "<none>") and (repo .. ":" .. tag) or img.Id
      return string.format("[%s:%s] %s", repo, tag, id), ref
    end

    local ref = (img.repository and img.repository ~= "<none>")
      and (img.repository .. ":" .. (img.tag or "latest"))
      or img.id
    return string.format(
      "[%s:%s] %s (%s)",
      img.repository or "<none>", img.tag or "<none>", img.id and img.id:sub(1, 12) or "<no id>", img.size or "?"
    ), ref
  end

  require("sandbox.telescope.picker").build({
    title = "Sandbox Images",
    items = images,
    entry = function(img)
      local text = describe(img)
      return { display = text, ordinal = text }
    end,
    keys = {
      { lhs = "<CR>", desc = "inspect", fn = function(img)
          local _, ref = describe(img)
          image_cmds.inspect(ref)
        end },
      { lhs = "<C-h>", desc = "history", fn = function(img)
          local _, ref = describe(img)
          image_cmds.history(ref)
        end },
      { lhs = "<C-d>", desc = "remove", fn = function(img)
          local _, ref = describe(img)
          image_cmds.remove(ref)
        end },
    },
  })
end
