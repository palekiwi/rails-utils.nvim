local M = {}

--- @return string? filepath
M.alterate_file = function()
  if vim.bo.filetype ~= "ruby" then return nil end

  local root, dirname, filename = string.match(vim.fn.expand("%:r"), "([^%/]+)/(.*)/([^%/]+)$")

  if root == "app" then
    return "spec/" .. dirname .. "/" .. filename .. "_spec.rb"
  elseif root == "spec" then
    return "app/" .. dirname .. "/" .. string.gsub(filename, "_spec$", "") .. ".rb"
  end
end

return M
