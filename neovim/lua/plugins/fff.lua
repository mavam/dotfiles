-- Fast fuzzy file and content search.
return {
  'dmtrKovalenko/fff.nvim',
  version = '*',
  build = function()
    require('fff.download').download_or_build_binary()
  end,
  lazy = false,
  config = function()
    require('fff').setup({
      lazy_sync = true,
    })

    vim.keymap.set('n', '<leader>f', function()
      require('fff').find_files()
    end, {
      silent = true,
      desc = 'Find files',
    })

    vim.keymap.set('n', '<leader>s', function()
      require('fff').live_grep()
    end, {
      silent = true,
      desc = 'Live grep',
    })

    vim.keymap.set('n', '<leader>gf', function()
      local git_root = vim.fs.root(0, { '.git' }) or vim.fn.getcwd()
      require('fff').find_files_in_dir(git_root)
    end, {
      silent = true,
      desc = 'Git files',
    })
  end,
}
