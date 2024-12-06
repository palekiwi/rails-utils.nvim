local utils  = require("rails-utils.utils")
local notify = require("notify")

local M = {}

local ns     = vim.api.nvim_create_namespace "rspec-live"

local scope  = {
  [1] = "file",
  [2] = "pr",
  [3] = "all",
}

local state  = {
  tests = {},
  error = nil,
}

vim.cmd("highlight TestSuccess guifg=#56d364")
vim.cmd("highlight TestFailure guifg=#f97583")

local format_output = function(entry)
  local output = {
    entry.description,
    '===',
    '',
    '## Error',
    entry.exception.class,
    '',
    '## Message',
    '```rb',
  }

  for _, msg in ipairs(vim.split(entry.exception.message, "\n")) do
    table.insert(output, msg)
  end

  table.insert(output, "```")
  table.insert(output, "")

  if entry.exception.backtrace ~= nil then
    table.insert(output, "## Backtrace")
    for _, val in ipairs(entry.exception.backtrace) do
      table.insert(output, val)
    end
  end

  return output
end

M.run_tests = function(opts)
  local notification
  local filenames = {}

  if opts.scope == scope[1] then
    table.insert(filenames, vim.fn.expand("%"))
  elseif scope[2] then
    filenames = utils.changed_files()
  end

  local files = {}
  for _, el in ipairs(filenames) do
    local spec = utils.spec_for(el)

    if spec and vim.fn.filereadable(spec) == 1 then
      vim.print(spec)
      files[spec] = true
    end
  end

  files = vim.tbl_keys(files)

  if #files == 0 then return end

  local cmd = "docker exec spabreaks-test-1 bin/rspec --format j " .. table.concat(files, " ")

  local file_list = table.concat(files, "\n")

  notification = notify(file_list, "info", {
    title = "Running tests...",
    hide_from_history = true,
    timeout = false,
    render = "simple"
  })

  vim.fn.jobstart(cmd, {
    stdout_buffered = true,

    on_stderr = function()
      state.error = "An error has occurred."
    end,

    on_stdout = function(_, data)
      if not data then
        return
      end

      for _, line_ in ipairs(data) do
        local line = line_:match('{".*}')
        if line then
          local decoded = vim.json.decode(line)

          state.tests = vim.tbl_map(function(ex)
            local result = {
              success = true,
              filename = ex.file_path,
              line = ex.line_number - 1,
              description = ex.description,
              pending = ex.pending_message == nil,
              exception = {}
            }

            if ex.status == "failed" then
              result = vim.tbl_deep_extend("force", result, {
                success = false,
                exception = ex.exception
              })
            end

            return result
          end, decoded.examples)
        end
      end
    end,

    on_exit = function(_)
      local failed = {}
      if #state.tests == 0 and state.error ~= nil then
        notify(state.error, "error", { title = "Error", replace = notification, timeout = 3000 })
        return
      end

      for _, test in ipairs(state.tests) do
        local bufnr = vim.fn.bufnr(test.filename, true)
        vim.diagnostic.reset(ns)
        vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

        local text = test.success and { "✓", "TestSuccess" } or { "× Test failed", "TestFailure" }

        if not test.success then
          failed[bufnr] = failed[bufnr] or {}

          table.insert(failed[bufnr], {
            bufnr = bufnr,
            lnum = test.line,
            col = 1,
            severity = vim.diagnostic.severity.ERROR,
            source = "rspec-live-tests",
            message = test.exception.message,
            user_data = {},
          })
        end

        if vim.api.nvim_get_current_buf() == bufnr then
          vim.api.nvim_buf_set_extmark(bufnr, ns, test.line, 0, {
            virt_text = { text },
          })
        end
      end

      for bufnr, entries in pairs(failed) do
        vim.diagnostic.set(ns, bufnr, entries, {})
      end

      if vim.tbl_isempty(failed) then
        notify(file_list, "info", { title = "Pass", replace = notification, timeout = 1000 })
      else
        notify(file_list, "error", { title = "Fail", replace = notification, timeout = 2000 })
      end
    end,
  })
end

M.show_diagnostics = function()
    require 'telescope.builtin'.diagnostics({ namespace = ns })
end

M.show_failure_details = function()
  local line = vim.fn.line "." - 1
  for _, test in pairs(state.tests) do
    if not test.success and test.line == line then
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_set_option_value("filetype", "markdown", { buf = buf })
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, format_output(test))
      vim.api.nvim_open_win(buf, false, { split = 'below', win = 0 })
    end
  end
end

return M
