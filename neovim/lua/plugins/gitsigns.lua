-- Add git related info in the signs columns and popups
return {
  'lewis6991/gitsigns.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim'
  },
  config = function()
    require'gitsigns'.setup {
      current_line_blame = true
    }
  end
}
