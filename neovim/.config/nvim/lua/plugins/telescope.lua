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
      vim.keymap.set('n', '<Tab>', function() require('telescope.builtin').buffers({sort_lastused = true, require('telescope.themes').get_ivy({})}) end, opts)
      vim.keymap.set('n', '<S-Tab>', function() require('telescope.builtin').git_files(require('telescope.themes').get_ivy({})) end, opts)
      vim.keymap.set('n', '<leader>sf', function() require('telescope.builtin').find_files({previewer = false}) end, opts)
      vim.keymap.set('n', '<leader>sb', function() require('telescope.builtin').current_buffer_fuzzy_find() end, opts)
      vim.keymap.set('n', '<leader>sh', function() require('telescope.builtin').help_tags() end, opts)
      vim.keymap.set('n', '<leader>st', function() require('telescope.builtin').tags() end, opts)
      vim.keymap.set('n', '<leader>sd', function() require('telescope.builtin').grep_string() end, opts)
      vim.keymap.set('n', '<leader>sp', function() require('telescope.builtin').live_grep() end, opts)
      vim.keymap.set('n', '<leader>so', function() require('telescope.builtin').tags{ only_current_buffer = true } end, opts)
      vim.keymap.set('n', '<leader>?', function() require('telescope.builtin').oldfiles() end, opts)
    end
}
