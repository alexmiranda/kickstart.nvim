-- Java development support via nvim-jdtls
-- Mason ensure_installed is configured in init.lua

---@param repo string
---@return string
local function gh(repo) return 'https://github.com/' .. repo end

-- nvim-jdtls (configured in ftplugin/java.lua)
vim.pack.add { gh 'mfussenegger/nvim-jdtls' }

-- Test runner
vim.pack.add {
  gh 'nvim-neotest/neotest',
  gh 'nvim-neotest/nvim-nio',
  gh 'nvim-lua/plenary.nvim',
  gh 'rcasia/neotest-java',
}

require('neotest').setup {
  adapters = {
    require('neotest-java') {},
  },
}

vim.keymap.set('n', '<leader>tt', function() require('neotest').run.run() end, { desc = '[T]est nearest' })
vim.keymap.set('n', '<leader>tT', function() require('neotest').run.run(vim.fn.expand '%') end, { desc = '[T]est file' })
vim.keymap.set('n', '<leader>ts', function() require('neotest').summary.toggle() end, { desc = '[T]est [S]ummary' })
vim.keymap.set('n', '<leader>to', function() require('neotest').output.open { enter = true } end, { desc = '[T]est [O]utput' })
vim.keymap.set('n', '<leader>tp', function() require('neotest').output_panel.toggle() end, { desc = '[T]est output [P]anel' })
vim.keymap.set('n', '<leader>td', function() require('neotest').run.run { strategy = 'dap' } end, { desc = '[T]est [D]ebug nearest' })

-- Debug adapter protocol
vim.pack.add {
  gh 'mfussenegger/nvim-dap',
  gh 'rcarriga/nvim-dap-ui',
}

local dap, dapui = require('dap'), require('dapui')
dapui.setup()
dap.listeners.after.event_initialized['dapui_config'] = function() dapui.open() end

vim.keymap.set('n', '<leader>du', function() dapui.toggle() end, { desc = '[D]ebug toggle [U]I' })
vim.keymap.set('n', '<leader>db', function() dap.toggle_breakpoint() end, { desc = '[D]ebug toggle [B]reakpoint' })
vim.keymap.set('n', '<leader>dc', function() dap.continue() end, { desc = '[D]ebug [C]ontinue' })
vim.keymap.set('n', '<leader>do', function() dap.step_over() end, { desc = '[D]ebug step [O]ver' })
vim.keymap.set('n', '<leader>di', function() dap.step_into() end, { desc = '[D]ebug step [I]nto' })

-- Register which-key groups
local wk_ok, wk = pcall(require, 'which-key')
if wk_ok then
  wk.add {
    { '<leader>d', group = '[D]ebug' },
    { '<leader>m', group = '[M]aven' },
    { '<leader>t', group = '[T]est' },
  }
end

-- Java formatting: IntelliJ format.sh with google-java-format fallback
-- Configured via conform.nvim (loaded in init.lua)
local conform_ok, conform = pcall(require, 'conform')
if conform_ok then
  conform.formatters.idea_format = {
    command = '/Applications/IntelliJ IDEA.app/Contents/bin/format.sh',
    args = { '-s', tostring(vim.env.IDEA_CODESTYLE or ''), '$FILENAME' },
    stdin = false,
    condition = function()
      local codestyle = vim.env.IDEA_CODESTYLE
      return codestyle and codestyle ~= ''
        and vim.fn.executable('/Applications/IntelliJ IDEA.app/Contents/bin/format.sh') == 1
    end,
  }
  conform.formatters_by_ft.java = { 'idea_format', 'google-java-format', stop_after_first = true }
end
