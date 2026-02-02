  -- UI to select things (files, grep results, open buffers...)
return {
    'nvim-telescope/telescope.nvim',
    dependencies = {
      'nvim-lua/popup.nvim',
      'nvim-lua/plenary.nvim'
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
      local opts = { silent = true }
      -- Navigation: restore jump list
      vim.keymap.set('n', '<S-Tab>', '<C-o>', opts)
      -- Core
      vim.keymap.set('n', '<leader>f', function() require('telescope.builtin').find_files() end, opts)
      vim.keymap.set('n', '<leader>b', function() require('telescope.builtin').buffers({ sort_lastused = true }) end, opts)
      vim.keymap.set('n', '<leader>s', function() require('telescope.builtin').live_grep() end, opts)
      vim.keymap.set('n', '<leader>h', function() require('telescope.builtin').help_tags() end, opts)
      vim.keymap.set('n', '<leader>k', function() require('telescope.builtin').keymaps() end, opts)
      -- Git
      vim.keymap.set('n', '<leader>gf', function() require('telescope.builtin').git_files() end, opts)
      vim.keymap.set('n', '<leader>gc', function() require('telescope.builtin').git_commits() end, opts)
      vim.keymap.set('n', '<leader>gb', function() require('telescope.builtin').git_branches() end, opts)
      vim.keymap.set('n', '<leader>gl', function() require('telescope.builtin').git_bcommits() end, opts)
    end
}
