# rails-utils.nvim

## Installation

With lazy.nvim:

```lua
{ "palekiwi/rails-utils.nvim" }
```

## Usage

Example mappings:

```lua
local rails_utils = require('rails-utils')

vim.keymap.set('n', '<leader>or', rails_utils.find_template_render)

vim.keymap.set('n', '<leader>ot', rails_utils.find_template)
```
