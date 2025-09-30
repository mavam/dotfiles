-- A neat status line.
return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'kyazdani42/nvim-web-devicons', opt = true },
  config = function()
    require('lualine').setup()
  end
}
