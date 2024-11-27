local builtin = require("telescope.builtin")

M = {}

-- tries to locate files which render the template in current buffer
M.find_template_render = function()
  local filename = vim.fn.expand("%:t:r:r"):gsub("^_", "")
  local regex = "(render|partial:)[\\s(]?[\'\"][^\\s]*" .. filename .. "[\'\"]\\B"

  builtin.grep_string(
    {
      search_dirs = { "app" },
      search = regex,
      use_regex = true
    }
  )
end

-- list templates with file names matching the word under cursor
M.find_template = function()
  builtin.find_files(
    {
      search_dirs = { "app/views" },
      default_text = vim.fn.expand("<cfile>")
    }
  )
end

M.alternate = function()
  if vim.bo.filetype ~= "ruby" then return end

  local root, dirname, filename = string.match(vim.fn.expand("%:r"), "([^%/]+)/(.*)/([^%/]+)$")

  if root == "app" then
    vim.cmd("e spec/" .. dirname .. "/" .. filename .. "_spec.rb")
  elseif root == "spec" then
    vim.cmd("e app/" .. dirname .. "/" .. string.gsub(filename, "_spec$", "") .. ".rb")
  end
end

return M
