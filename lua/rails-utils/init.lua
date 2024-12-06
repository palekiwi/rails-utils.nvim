local has_telescope = pcall(require, "telescope")
local lib = require("rails-utils.lib")
local live_test = require("rails-utils.live_test")

if not has_telescope then
  error("This plugin requires nvim-telescope/telescope.nvim")
end

return {
  lib = lib,
  live_test = live_test,
}
