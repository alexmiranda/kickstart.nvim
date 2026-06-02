-- Remap mini.surround to tpope-style keybindings
-- Returns empty spec; configuration is applied via autocmd after mini.nvim loads

vim.api.nvim_create_autocmd('User', {
  pattern = 'VeryLazy',
  once = true,
  callback = function()
    require('mini.surround').setup({
      mappings = {
        add = 'ys',
        delete = 'ds',
        replace = 'cs',
        find = '',
        find_left = '',
        highlight = '',
        update_n_lines = '',
      },
    })
    vim.keymap.set('x', 'S', [[:<C-u>lua MiniSurround.add('visual')<CR>]], { desc = 'Add surrounding' })
  end,
})

return {}
