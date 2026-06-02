-- Nix development support
-- All tools from Nix PATH: nixd, nixfmt, statix, deadnix

-- Configure nixd LSP directly using Neovim 0.11+ native APIs.
-- nixd is not in Mason's registry, so we configure it outside the
-- Mason-managed servers table in init.lua.
vim.lsp.config('nixd', {
  cmd = { 'nixd' },
  filetypes = { 'nix' },
  root_markers = { 'flake.nix', 'flake.lock', '.git' },
  settings = {
    nixd = {
      nixpkgs = {
        expr = 'import <nixpkgs> { }',
      },
      formatting = {
        command = { 'nixfmt' },
      },
    },
  },
})
vim.lsp.enable('nixd')

-- Add Nix formatter to conform.nvim
local conform_ok, conform = pcall(require, 'conform')
if conform_ok then
  conform.formatters_by_ft.nix = { 'nixfmt' }
end
