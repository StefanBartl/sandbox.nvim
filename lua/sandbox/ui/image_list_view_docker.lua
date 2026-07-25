--- View for listing all Docker images, with buffer-local keymaps to act on
--- the image under the cursor (see `?` inside the buffer).
--- @param images table[]
local notify = require("sandbox.notify")
local list_actions = require("sandbox.ui.list_actions")
return function(images)
  if type(images) ~= "table" then
    notify.error("Invalid image list: not a table")
    return
  end

  local lines = {}
  for _, image in ipairs(images) do
    table.insert(lines, string.format(
      "[%s:%s] %s (%s)",
      image.repository or "<none>",
      image.tag or "<none>",
      image.id and image.id:sub(1, 12) or "<no id>",
      image.size or "unknown size"
    ))
  end

  local bufnr = require("lib.nvim.window").open_named_scratch(
    "sandbox.nvim://image-list", lines, { filetype = "log", split = "left" }
  )

  local image_cmds = require("sandbox.bindings.usrcmds.image_commands")
  ---@param img table
  local function ref(img)
    if img.repository and img.repository ~= "<none>" then
      return img.repository .. ":" .. (img.tag or "latest")
    end
    return img.id
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
  }, images, 0)
end
