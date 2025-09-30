-- Display a character as the virtual column.
return {
  'lukas-reineke/virt-column.nvim',
  config = function()
    require('virt-column').setup()
  end,
}
