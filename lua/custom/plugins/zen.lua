-- Zen mode for focused editing

---@module 'lazy'
---@type LazySpec
return {
  {
    'folke/zen-mode.nvim',
    keys = {
      { '<leader>tz', '<cmd>ZenMode<cr>', desc = '[T]oggle [Z]en mode' },
    },
    opts = {
      window = {
        width = 120,
      },
    },
  },
}
