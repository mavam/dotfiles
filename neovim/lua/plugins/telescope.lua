-- Secondary picker UI for buffers, help, and git metadata.
return {
  'nvim-telescope/telescope.nvim',
  dependencies = {
    'nvim-lua/popup.nvim',
    'nvim-lua/plenary.nvim',
  },
  config = function()
    require('telescope').setup {
      defaults = {
        mappings = {
          i = {
            ['<C-u>'] = false,
            ['<C-d>'] = false,
          },
        },
      },
    }

    -- Navigation: restore jump list
    vim.keymap.set('n', '<S-Tab>', '<C-o>', {
      silent = true,
      desc = 'Jump back',
    })

    vim.keymap.set('n', '<leader>b', function()
      require('telescope.builtin').buffers({ sort_lastused = true })
    end, {
      silent = true,
      desc = 'Buffers',
    })

    vim.keymap.set('n', '<leader>h', function()
      require('telescope.builtin').help_tags()
    end, {
      silent = true,
      desc = 'Help tags',
    })

    vim.keymap.set('n', '<leader>k', function()
      require('telescope.builtin').keymaps()
    end, {
      silent = true,
      desc = 'Keymaps',
    })

    -- Git
    vim.keymap.set('n', '<leader>gc', function()
      require('telescope.builtin').git_commits()
    end, {
      silent = true,
      desc = 'Git commits',
    })

    vim.keymap.set('n', '<leader>gb', function()
      require('telescope.builtin').git_branches()
    end, {
      silent = true,
      desc = 'Git branches',
    })

    vim.keymap.set('n', '<leader>gl', function()
      require('telescope.builtin').git_bcommits()
    end, {
      silent = true,
      desc = 'Git buffer commits',
    })
  end,
}
