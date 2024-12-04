local utils  = require("rails-utils.utils")
local notify = require("notify")

local ns     = vim.api.nvim_create_namespace "rspec-live"
local group  = vim.api.nvim_create_augroup("rspec-test", { clear = true })

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

local attach_to_buffer = function()
  local state = {
    tests = {},
    error = nil,
  }

  vim.api.nvim_create_user_command("RSpecLineFail", function()
    local line = vim.fn.line "." - 1
    for _, test in pairs(state.tests) do
      if not test.success and test.line == line then
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_set_option_value("filetype", "markdown", { buf = buf })
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, format_output(test))
        vim.api.nvim_open_win(buf, false, { split = 'below', win = 0 })
      end
    end
  end, {})

  vim.api.nvim_create_user_command("RSpecDiagnostics", function()
    require'telescope.builtin'.diagnostics({ namespace = ns})
  end, {})

  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    group = group,
    pattern = "*.rb",
    callback = function()
      local notification
      local filename = vim.fn.expand("%")

      state.spec_file = true

      if not string.match(filename, "_spec.rb$") then
        local filename_ = utils.alternate_file()
        if filename_ == nil or vim.fn.filereadable(filename_) == 0 then return end

        state.spec_file = false
        filename = filename_
      end

      local cmd = "docker exec spabreaks-test-1 bin/rspec " .. filename .. " --format j"

      notification = notify(filename, "info", {
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
            notify(filename, "info", { title = "Pass", replace = notification, timeout = 1000 })
          else
            notify(filename, "error", { title = "Fail", replace = notification, timeout = 2000 })
          end
        end,
      })
    end
  })
end

attach_to_buffer()
