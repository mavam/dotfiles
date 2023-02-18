-- Colorscheme
return {
  'catppuccin/nvim',
  as = 'catppuccin',
  config = function()
    require('catppuccin').setup({
      background = {
        light = "latte",
        dark = "mocha",
      },
    })
    vim.o.background = 'dark'
    vim.o.termguicolors = true
    -- vim.cmd 'highlight WinSeparator NONE'
    vim.cmd.colorscheme 'catppuccin'
  end
}
