--- Render a list of container images in a new buffer, with buffer-local
--- keymaps to act on the image under the cursor (see `?` inside the buffer).
--- @param images table[]
local list_actions = require("sandbox.ui.list_actions")
return function(images)
  local format_bytes = require("lib.lua.strings.format").format_bytes
  local lines = {}

  table.insert(lines, "REPOSITORY                 TAG         IMAGE ID        SIZE")
  table.insert(lines, string.rep("-", 65))

  ---@param img table
  ---@return string repo
  ---@return string tag
  local function repo_tag(img)
    local name = (img.Names or {})[1] or "<none>:<none>"
    local repo, tag = name:match("^(.-):([^:]+)$")
    return repo or "<none>", tag or "<none>"
  end

  for _, img in ipairs(images) do
    local repo, tag = repo_tag(img)
    local id = (img.Id or ""):sub(1, 12)
    local size = format_bytes(tonumber(img.Size) or 0)

    table.insert(lines, string.format("%-26s %-11s %-15s %s", repo, tag, id, size))
  end

  local list_opts = require("sandbox.config").options
  local bufnr = require("lib.nvim.window").open_named_scratch(
    "sandbox.nvim://images", lines,
    { filetype = "markdown", split = list_opts.list_split, size = list_opts.list_size }
  )

  local image_cmds = require("sandbox.bindings.usrcmds.image_commands")
  ---@param img table
  local function ref(img)
    local repo, tag = repo_tag(img)
    if repo ~= "<none>" then
      return repo .. ":" .. tag
    end
    return img.Id
  end

  list_actions.set_keymaps(bufnr, {
    { lhs = "<CR>", desc = "inspect", fn = function(img) image_cmds.inspect(ref(img)) end },
    { lhs = "i", desc = "inspect", fn = function(img) image_cmds.inspect(ref(img)) end },
    { lhs = "h", desc = "history", fn = function(img) image_cmds.history(ref(img)) end },
    { lhs = "t", desc = "tag", fn = function(img)
        vim.ui.input({ prompt = "Tag " .. ref(img) .. " as: " }, function(target)
          if target and target ~= "" then
            image_cmds.tag(ref(img), target)
          end
        end)
      end },
    { lhs = "D", desc = "remove", fn = function(img) image_cmds.remove(ref(img)) end },
    { lhs = "R", desc = "refresh list", no_item = true, fn = function() image_cmds.list() end },
  }, images, 2)

  list_actions.setup_autorefresh(bufnr, image_cmds.list)
end
