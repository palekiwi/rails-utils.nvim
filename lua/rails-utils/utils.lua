local M = {}

--- @return string? filepath
M.alternate_file = function()
  if vim.bo.filetype ~= "ruby" then return nil end

  local root, dirname, filename = string.match(vim.fn.expand("%:r"), "([^%/]+)/(.*)/([^%/]+)$")

  if root == "app" then
    return "spec/" .. dirname .. "/" .. filename .. "_spec.rb"
  elseif root == "spec" then
    return "app/" .. dirname .. "/" .. string.gsub(filename, "_spec$", "") .. ".rb"
  end
end

M.spec_for = function(filepath)
  local root, dirname, filename = string.match(filepath, "([^%/]+)/(.*)/([^%/]+).rb$")

  if root == "app" then
    return "spec/" .. dirname .. "/" .. filename .. "_spec.rb"
  else
    return filepath
  end
end

M.changed_files = function()
  local base_branch = vim.g.git_base or "master"
  local command = "git diff --name-only $(git merge-base HEAD " .. base_branch .. " )"

  local handle = assert(io.popen(command))
  local result = handle:read("*a")
  handle:close()

  local files = {}

  for token in string.gmatch(result, "[^%s]+") do
    table.insert(files, token)
  end

  return files
end

return M
