-- Remap mini.surround to tpope-style keybindings
-- mini.nvim is loaded in init.lua; this reconfigures surround mappings

require('mini.surround').setup {
  mappings = {
    add = 'ys',
    delete = 'ds',
    replace = 'cs',
    find = '',
    find_left = '',
    highlight = '',
    update_n_lines = '',
  },
}
vim.keymap.set('x', 'S', [[:<C-u>lua MiniSurround.add('visual')<CR>]], { desc = 'Add surrounding' })
