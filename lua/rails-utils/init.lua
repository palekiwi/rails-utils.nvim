local has_telescope = pcall(require, "telescope")

local config = require("rails-utils.config")
local files = require("rails-utils.files")
local live_test = require("rails-utils.live_test")

if not has_telescope then
  error("This plugin requires nvim-telescope/telescope.nvim")
end

local rails_utils = {}

rails_utils.setup = function(opts)
  opts = opts or {}

  for k, _ in pairs(config) do
    if opts[k] ~= nil then
      config[k] = opts[k]
    end
  end

  vim.cmd("highlight RSpecTestSuccess guifg=" .. config.colors.test_success)
  vim.cmd("highlight RSpecTestFailure guifg=" .. config.colors.test_failure)
end

rails_utils.alternate = files.alternate
rails_utils.find_template = files.find_template
rails_utils.find_template_render = files.find_template_render
rails_utils.run_tests = live_test.run_tests
rails_utils.show_diagnostics = live_test.show_diagnostics
rails_utils.show_failure_details = live_test.show_failure_details

return rails_utils
