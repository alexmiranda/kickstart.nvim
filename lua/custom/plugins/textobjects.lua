-- Treesitter-powered text objects for function, class, argument, block, etc.
-- Reconfigures mini.ai after init.lua via VeryLazy (same pattern as surround.lua)

vim.api.nvim_create_autocmd('User', {
  pattern = 'VeryLazy',
  once = true,
  callback = function()
    local ai = require('mini.ai')
    local gen_spec = ai.gen_spec
    ai.setup({
      n_lines = 500,
      custom_textobjects = {
        f = gen_spec.treesitter({ a = '@function.outer', i = '@function.inner' }),
        c = gen_spec.treesitter({ a = '@class.outer', i = '@class.inner' }),
        a = gen_spec.treesitter({ a = '@parameter.outer', i = '@parameter.inner' }),
        o = gen_spec.treesitter({ a = '@block.outer', i = '@block.inner' }),
        l = gen_spec.treesitter({ a = '@loop.outer', i = '@loop.inner' }),
        i = gen_spec.treesitter({ a = '@conditional.outer', i = '@conditional.inner' }),
      },
    })
  end,
})

---@module 'lazy'
---@type LazySpec
return {
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
  },
}
