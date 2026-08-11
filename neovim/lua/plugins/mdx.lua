return {
  'davidmh/mdx.nvim',
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
  },
  init = function()
    require('config.starlight-callouts').setup()
  end,
}
