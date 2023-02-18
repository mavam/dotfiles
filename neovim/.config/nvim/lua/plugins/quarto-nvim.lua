-- Quarto integration.
return {
  'quarto-dev/quarto-nvim',
  dependencies = {
    'jmbuhr/otter.nvim',
    {
      'quarto-dev/quarto-vim',
      dev = false,
      dependencies = { 'vim-pandoc/vim-pandoc-syntax' },
    },
    'neovim/nvim-lspconfig'
  },
  config = function()
    vim.opt.conceallevel = 0
    -- disable conceal in markdown/quarto
    vim.g['pandoc#syntax#conceal#use'] = false
    -- embeds are already handled by treesitter injectons
    vim.g['pandoc#syntax#codeblocks#embeds#use'] = false
    vim.g['pandoc#syntax#conceal#blacklist'] = { 'codeblock_delim', 'codeblock_start' }
    -- but allow some types of conceal in math reagions:
    -- a=accents/ligatures d=delimiters m=math symbols
    -- g=Greek  s=superscripts/subscripts
    vim.g['tex_conceal'] = 'gm'
    require 'quarto'.setup {
      lspFeatures = {
        enabled = true,
        languages = { 'r', 'python', 'julia' },
        diagnostics = {
          enabled = true,
          triggers = { "BufWrite" }
        },
        completion = {
          enabled = true
        }
      }
    }
  end
}
