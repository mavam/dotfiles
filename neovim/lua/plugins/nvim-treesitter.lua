-- TreeSitter integration, and additional textobjects for it.
return {
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  dependencies = {
    'tenzir/tree-sitter-tql',
    'nvim-treesitter/nvim-treesitter-refactor',
  },
  config = function()
    require('nvim-treesitter.configs').setup {
      ensure_installed = {
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
      },
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = true,
      },
      refactor = {
        highlight_definitions = { enable = true },
        highlight_current_scope = { enable = true },
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = '<CR>',
          scope_incremental = '<CR>',
          node_incremental = '<TAB>',
          node_decremental = '<S-TAB>',
        },
      },
    }

    local parsers = require('nvim-treesitter.parsers').get_parser_configs()
    parsers.tql = parsers.tql or {}
    parsers.tql.install_info = parsers.tql.install_info or {
      url = 'https://github.com/tenzir/tree-sitter-tql',
      files = { 'src/parser.c' },
      branch = 'main',
    }
    parsers.tql.filetype = 'tql'

    vim.filetype.add({ extension = { tql = 'tql' } })

    local set_hl = vim.api.nvim_set_hl
    set_hl(0, 'TSDefinition', { underline = true })
    set_hl(0, 'TSDefinitionUsage', { underline = true })
    set_hl(0, 'TSCurrentScope', { link = 'Normal' })
    set_hl(0, 'TSDefinitionUsage', { link = 'TSDefinition' })
  end,
}
