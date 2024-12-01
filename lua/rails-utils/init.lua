local has_telescope = pcall(require, "telescope")
local lib = require("rails-utils.lib")

require("rails-utils.autocmd")

if not has_telescope then
  error("This plugin requires nvim-telescope/telescope.nvim")
end

return lib
