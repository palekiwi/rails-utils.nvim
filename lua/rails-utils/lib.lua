local builtin = require("telescope.builtin")
local utils = require("rails-utils.utils")

M = {}

--- tries to locate files which render the template in current buffer
M.find_template_render = function()
  if vim.bo.filetype == "eruby" then
    local dir, filename = string.match(vim.fn.expand("%:r:r"), "app/views/([^ ]*)/_?([^%s]*)")

    local controller_file = "app/controllers/" .. dir .. "_controller.rb"
    local cmd = "rg -n 'def " .. filename .. "' " .. controller_file

    local handle = assert(io.popen(cmd))
    local result = handle:read("*a")
    handle:close()

    local line = result:match("^%d+")

    if line ~= nil then
      return vim.cmd(string.format("e +%s %s", line, controller_file))
    end

    local regex = "((\\s+(render|partial:)\\s*\\(?)|^\\s*)[\'\"](" .. dir .. "/)?" .. filename .. "[\'\"]"

    builtin.grep_string(
      {
        search_dirs = { "app/controllers", "app/views" },
        search = regex,
        use_regex = true
      }
    )
  elseif vim.bo.filetype == "ruby" then
    local dir, filename = string.match(vim.fn.expand("%:r:r"), "app/controllers/?([^ ]*)/([^%s]*)_controller")
    local method = vim.fn.expand("<cword>")
    local path

    if dir ~= "" then
      path = "app/views/" .. dir  .. "/" .. filename
    else
      path = "app/views/" .. filename
    end

    builtin.find_files(
      {
        search_dirs = { path },
        search_file = method .. "."
      }
    )
  end
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
  local filepath = utils.alternate_file()
  if filepath == nil then
    return
  end

  vim.cmd("e " .. filepath)
end

return M
