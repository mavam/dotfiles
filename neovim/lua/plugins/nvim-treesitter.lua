-- TreeSitter integration.
return {
  'nvim-treesitter/nvim-treesitter',
  branch = 'main',
  lazy = false,
  build = ':TSUpdate',
  dependencies = {
    'tenzir/tree-sitter-tql',
  },
  config = function()
    -- Register the custom TQL parser.
    vim.api.nvim_create_autocmd('User', {
      pattern = 'TSUpdate',
      callback = function()
        require('nvim-treesitter.parsers').tql = {
          install_info = {
            url = 'https://github.com/tenzir/tree-sitter-tql',
            branch = 'main',
          },
        }
      end,
    })

    -- Install parsers (no-op if already installed).
    require('nvim-treesitter').install {
      'bash',
      'c',
      'comment',
      'cpp',
      'fish',
      'json',
      'lua',
      'markdown',
      'python',
      'r',
      'tql',
      'yaml',
    }

    -- Enable treesitter highlighting for supported filetypes.
    vim.api.nvim_create_autocmd('FileType', {
      pattern = {
        'bash', 'sh', 'c', 'cpp', 'fish', 'json', 'lua', 'markdown',
        'python', 'r', 'tql', 'yaml',
      },
      callback = function()
        vim.treesitter.start()
      end,
    })

    vim.filetype.add({ extension = { tql = 'tql' } })
  end,
}
