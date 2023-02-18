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
    -- vim.cmd 'highlight WinSeparator NONE'
    vim.cmd.colorscheme 'catppuccin'
  end
}
