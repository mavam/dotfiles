return {
  'f-person/auto-dark-mode.nvim',
  as = 'auto-dark-mode',
  lazy = false,
  config = function()
    require('auto-dark-mode').setup({
      set_dark_mode = function()
        --vim.api.nvim_set_option_value('background', 'dark', {})
        vim.cmd.colorscheme 'github_dark'
      end,
      set_light_mode = function()
        --vim.api.nvim_set_option_value('background', 'light', {})
        vim.cmd.colorscheme 'github_light'
      end,
      update_interval = 1000,
      fallback = 'dark',
    })
  end
}
