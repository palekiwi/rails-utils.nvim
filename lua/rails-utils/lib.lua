local builtin = require("telescope.builtin")

M = {}

--- tries to locate files which render the template in current buffer
M.find_template_render = function()
  if vim.bo.filetype ~= "eruby" then return end

  local dir, filename = string.match(vim.fn.expand("%:r:r"), "app/views/([^ ]*)/_?([^%s]*)")
  local regex = "(((render|partial:)\\s+\\(?*)|^\\s*)[\'\"](" .. dir .. "/)?" .. filename .. "[\'\"]"

  builtin.grep_string(
    {
      search_dirs = { "app/controllers", "app/views" },
      search = regex,
      use_regex = true
    }
  )
end

--- list templates with file names matching the word under cursor
M.find_template = function()
  builtin.find_files(
    {
      search_dirs = { "app/views" },
      default_text = vim.fn.expand("<cfile>")
    }
  )
end

--- returns alternate file in either app/ or spec/
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
