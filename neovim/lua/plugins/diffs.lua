-- Treesitter-powered diff syntax highlighting.
return {
  'barrettruth/diffs.nvim',
  init = function()
    vim.g.diffs = {
      integrations = {
        fugitive = true,
        gitsigns = true,
      },
    }
  end,
}
