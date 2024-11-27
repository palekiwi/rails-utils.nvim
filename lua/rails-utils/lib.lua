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
  local filepath = vim.fn.expand("%")
  if filepath == "" then return end

  local parent = string.match(filepath, "[^%/]+")
  local filename = string.match(filepath, "([^%/]+)%.rb$")
  local no_filename = string.gsub(filepath, "[^%/]+%.rb$", "")
  local rest = string.gsub(no_filename, "^[^%/]+", "")

  if parent == "app" then
    vim.cmd("e spec" .. rest .. filename .. "_spec.rb")
  elseif parent == "spec" then
    vim.cmd("e app" .. rest .. string.gsub(filename, "_spec$", "") .. ".rb")
  end
end

return M
