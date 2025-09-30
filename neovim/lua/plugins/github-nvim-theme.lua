-- Colorscheme
return {
  'projekt0n/github-nvim-theme',
  as = 'github-theme',
  config = function()
    require('github-theme').setup({
      options = {
        transparent = true,
      },
    })
    -- vim.cmd 'highlight WinSeparator NONE'
    vim.cmd.colorscheme 'github_light'
  end
}
