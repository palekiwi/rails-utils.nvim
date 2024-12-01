local ns               = vim.api.nvim_create_namespace "rspec-live"
local group            = vim.api.nvim_create_augroup("rspec-test", { clear = true })

vim.cmd("highlight TestSuccess guifg=#56d364")
vim.cmd("highlight TestFailure guifg=#f97583")

local attach_to_buffer = function(bufnr)
  local state = {
    bufnr = bufnr,
    tests = {},
  }

  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    group = group,
    pattern = "*_spec.rb",
    callback = function()
      local filename = vim.fn.expand("%")
      local cmd = "docker exec spabreaks-test-1 bin/rspec " .. filename .. " --format j"

      vim.fn.jobstart(cmd, {
        stdout_buffered = true,

        on_stdout = function(_, data)
          if not data then
            return
          end

          local start_line = 1

          while data[start_line] and not data[start_line]:find('{".*}') do
            start_line = start_line + 1
          end

          if data[start_line] then
            local decoded = vim.json.decode(data[start_line])

            state.tests = vim.tbl_map(function(ex)
              local result = { success = true, line = ex.line_number - 1, description = ex.description, message = "" }

              if ex.status == "failed" then
                result = vim.tbl_deep_extend("force", result, {
                  success = false,
                  message = ex.exception.message
                })
              end

              return result
            end, decoded.examples)
          end
        end,

        on_exit = function(_)
          local failed = {}
          vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

          for _, test in ipairs(state.tests) do
            local text = test.success and { "✓", "TestSuccess" } or { "× Test failed", "TestFailure" }

            vim.api.nvim_buf_set_extmark(bufnr, ns, test.line, 0, {
              virt_text = { text },
            })

            if not test.success then
              table.insert(failed, {
                bufnr = bufnr,
                lnum = test.line,
                col = 1,
                end_col = 3,
                severity = vim.diagnostic.severity.ERROR,
                source = "rspec-live-tests",
                message = test.message,
                user_data = {},
              })
            end
          end

          if #failed > 0 then
            vim.notify("Failed: " .. #failed, vim.log.levels.ERROR)
          else
            vim.notify("Pass.\n.100")
          end

          vim.diagnostic.set(ns, bufnr, failed, {})
        end,
      })
    end
  })
end

attach_to_buffer(vim.api.nvim_get_current_buf())
