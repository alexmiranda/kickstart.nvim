-- Treesitter-powered text objects for function, class, argument, block, etc.

---@param repo string
---@return string
local function gh(repo) return 'https://github.com/' .. repo end

vim.pack.add { gh 'nvim-treesitter/nvim-treesitter-textobjects' }

local ai = require('mini.ai')
local gen_spec = ai.gen_spec
ai.setup {
  n_lines = 500,
  custom_textobjects = {
    f = gen_spec.treesitter { a = '@function.outer', i = '@function.inner' },
    c = gen_spec.treesitter { a = '@class.outer', i = '@class.inner' },
    a = gen_spec.treesitter { a = '@parameter.outer', i = '@parameter.inner' },
    o = gen_spec.treesitter { a = '@block.outer', i = '@block.inner' },
    l = gen_spec.treesitter { a = '@loop.outer', i = '@loop.inner' },
    i = gen_spec.treesitter { a = '@conditional.outer', i = '@conditional.inner' },
  },
}
