-- Zen mode for focused editing

---@param repo string
---@return string
local function gh(repo) return 'https://github.com/' .. repo end

vim.pack.add { gh 'folke/zen-mode.nvim' }

require('zen-mode').setup {
  window = {
    width = 120,
  },
}

vim.keymap.set('n', '<leader>tz', '<cmd>ZenMode<cr>', { desc = '[T]oggle [Z]en mode' })
