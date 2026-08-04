---@module 'sandbox.util.devcontainer_file'
--- Detect and parse a devcontainer.json in the cwd or an ancestor
--- directory, matching VS Code's own lookup order:
--- `.devcontainer/devcontainer.json`, then `.devcontainer.json`.
--- devcontainer.json is JSONC (// and /* */ comments, trailing commas
--- allowed) -- vim.fn.json_decode is strict JSON, so comments/trailing
--- commas are stripped first.

local M = {}

--- @return string|nil path to the nearest devcontainer.json
function M.find()
  -- vim.fs.find's `upward = true` only checks each ancestor directory's own
  -- direct children -- it never recurses into a `.devcontainer/` subfolder,
  -- so the nested `.devcontainer/devcontainer.json` case needs a manual walk.
  local dir = vim.fn.getcwd()
  while true do
    local nested = dir .. "/.devcontainer/devcontainer.json"
    if vim.fn.filereadable(nested) == 1 then
      return nested
    end

    local flat = dir .. "/.devcontainer.json"
    if vim.fn.filereadable(flat) == 1 then
      return flat
    end

    local parent = vim.fs.dirname(dir)
    if not parent or parent == dir then
      return nil
    end
    dir = parent
  end
end

--- The project root a devcontainer.json's paths (workspaceFolder,
--- dockerComposeFile, build.context, ...) are relative to.
--- @param path string result of M.find()
--- @return string
function M.workspace_dir(path)
  if vim.fs.basename(path) == "devcontainer.json" then
    return vim.fs.dirname(vim.fs.dirname(path)) -- .../.devcontainer/devcontainer.json
  end
  return vim.fs.dirname(path) -- .../.devcontainer.json
end

---@internal
--- Strip JSONC comments (respecting string literals, so `//`/`/*` inside a
--- string value is left alone) and trailing commas, then decode.
--- @param text string
--- @return table|nil config, string|nil err
local function decode_jsonc(text)
  local out = {}
  local i, n = 1, #text
  local in_string = false
  local escape = false

  while i <= n do
    local c = text:sub(i, i)

    if in_string then
      out[#out + 1] = c
      if escape then
        escape = false
      elseif c == "\\" then
        escape = true
      elseif c == '"' then
        in_string = false
      end
      i = i + 1
    elseif c == '"' then
      in_string = true
      out[#out + 1] = c
      i = i + 1
    elseif c == "/" and text:sub(i + 1, i + 1) == "/" then
      while i <= n and text:sub(i, i) ~= "\n" do
        i = i + 1
      end
    elseif c == "/" and text:sub(i + 1, i + 1) == "*" then
      i = i + 2
      while i <= n and not (text:sub(i, i) == "*" and text:sub(i + 1, i + 1) == "/") do
        i = i + 1
      end
      i = i + 2
    else
      out[#out + 1] = c
      i = i + 1
    end
  end

  local cleaned = table.concat(out):gsub(",(%s*[%}%]])", "%1")

  local ok, result = pcall(vim.fn.json_decode, cleaned)
  if not ok or type(result) ~= "table" then
    return nil, "invalid devcontainer.json: " .. tostring(result)
  end
  return result, nil
end

--- @param path string
--- @return table|nil config, string|nil err
function M.parse(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return nil, "failed to read " .. path
  end
  return decode_jsonc(table.concat(lines, "\n"))
end

return M
