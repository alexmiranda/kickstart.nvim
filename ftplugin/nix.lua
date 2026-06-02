-- Nix-specific keymaps and settings
-- Loaded automatically when opening .nix files

-- Fix and format: run deadnix + statix + nixfmt (semantic fixes + formatting)
vim.keymap.set('n', '<leader>cf', function()
  require('conform').format {
    async = true,
    formatters = { 'deadnix', 'statix', 'nixfmt' },
  }
end, { buffer = true, desc = '[C]ode [F]ix Nix (deadnix + statix + nixfmt)' })
