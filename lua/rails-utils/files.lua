local builtin = require("telescope.builtin")
local utils = require("rails-utils.utils")

M = {}
--- tries to locate files which render the template in current buffer
M.find_template_render = function()
  if vim.bo.filetype == "eruby" then
    local current_file = vim.fn.expand("%:r:r")
    local dir, filename = string.match(current_file, "app/views/(.*)/_?([^%s]*)")

    -- Check if we successfully extracted dir and filename
    if not dir or not filename then
      vim.notify("Could not parse view file path: " .. current_file, vim.log.levels.WARN)
      return
    end

    local controller_prefix = string.match(dir, "([^/]*)")

    local controller_file = "app/controllers/" .. controller_prefix .. "_controller.rb"

    -- Check if controller file exists before trying to search it
    if vim.fn.filereadable(controller_file) == 0 then
      vim.notify("Controller file not found: " .. controller_file, vim.log.levels.WARN)
      return
    end

    local cmd = "rg -n 'def " .. filename .. "' " .. controller_file
    local handle = io.popen(cmd)

    if not handle then
      vim.notify("Failed to execute ripgrep command", vim.log.levels.ERROR)
      return
    end

    local result = handle:read("*a")
    local success, _, exit_code = handle:close()

    -- Check if command executed successfully
    if not success or exit_code ~= 0 then
      -- Command failed, fall through to grep_string search
    else
      local line = result:match("^%d+")
      if line then
        return vim.cmd(string.format("e +%s %s", line, controller_file))
      end
    end

    -- Fallback to telescope search if available
    if builtin and builtin.grep_string then
      local regex = "((\\s+(render|partial:)\\s*\\(?)|^\\s*)[\'\"](" .. dir .. "/)?" .. filename .. "[\'\"]"
      builtin.grep_string({
        search_dirs = { "app/controllers", "app/views" },
        search = regex,
        use_regex = true
      })
    else
      vim.notify("Telescope builtin not available for fallback search", vim.log.levels.WARN)
    end
  elseif vim.bo.filetype == "ruby" then
    local current_file = vim.fn.expand("%:r:r")
    local dir, filename = string.match(current_file, "app/controllers/?([^/]*)/([^%s]*)_controller")

    -- Handle case where controller is in root controllers directory
    if not dir then
      dir, filename = "", string.match(current_file, "app/controllers/([^%s]*)_controller")
    end

    if not filename then
      vim.notify("Could not parse controller file path: " .. current_file, vim.log.levels.WARN)
      return
    end

    local method = vim.fn.expand("<cword>")
    if method == "" then
      vim.notify("No word under cursor", vim.log.levels.WARN)
      return
    end

    local path
    if dir ~= "" then
      path = "app/views/" .. dir .. "/" .. filename
    else
      path = "app/views/" .. filename
    end

    -- Check if the views directory exists
    if vim.fn.isdirectory(path) == 0 then
      vim.notify("Views directory not found: " .. path, vim.log.levels.WARN)
      return
    end

    -- Use telescope if available
    if builtin and builtin.find_files then
      builtin.find_files({
        search_dirs = { path },
        search_file = method .. "."
      })
    else
      vim.notify("Telescope builtin not available", vim.log.levels.WARN)
    end
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
    vim.notify("no filepath")
    return
  end

  vim.cmd("e " .. filepath)
end

return M
