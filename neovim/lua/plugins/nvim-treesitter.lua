-- TreeSitter integration.
local parsers = {
  'bash',
  'c',
  'comment',
  'cpp',
  'fish',
  'json',
  'lua',
  'markdown',
  'markdown_inline',
  'python',
  'r',
  'tql',
  'typescript',
  'tsx',
  'yaml',
}

local function register_tql_parser()
  require('nvim-treesitter.parsers').tql = {
    install_info = {
      url = 'https://github.com/tenzir/tree-sitter-tql',
      branch = 'main',
    },
  }
end

local function warn_missing_tree_sitter(treesitter)
  local installed = treesitter.get_installed('parsers')
  local missing = vim.tbl_filter(function(parser)
    return not vim.list_contains(installed, parser)
  end, parsers)

  if #missing == 0 then
    return
  end

  vim.schedule(function()
    vim.notify_once(
      'tree-sitter CLI not found; skipping parser installation for: '
        .. table.concat(missing, ', ')
        .. '. Install it with `brew install tree-sitter-cli` and run :TSUpdate.',
      vim.log.levels.WARN,
      { title = 'nvim-treesitter' }
    )
  end)
end

return {
  'nvim-treesitter/nvim-treesitter',
  branch = 'main',
  lazy = false,
  build = ':TSUpdate',
  dependencies = {
    'tenzir/tree-sitter-tql',
  },
  config = function()
    local treesitter = require('nvim-treesitter')

    vim.api.nvim_create_autocmd('User', {
      group = vim.api.nvim_create_augroup('dotfiles-treesitter', { clear = true }),
      pattern = 'TSUpdate',
      callback = register_tql_parser,
    })
    register_tql_parser()

    -- Keep parser installs alongside the plugin, matching :TSUpdate.
    treesitter.setup {
      install_dir = require('nvim-treesitter.install').get_package_path(),
    }

    -- Only try to install/update parsers when the tree-sitter CLI is present.
    if vim.fn.executable('tree-sitter') == 1 then
      treesitter.install(parsers)
    else
      warn_missing_tree_sitter(treesitter)
    end

    -- Enable treesitter highlighting for supported filetypes.
    vim.api.nvim_create_autocmd('FileType', {
      pattern = {
        'bash', 'sh', 'c', 'cpp', 'fish', 'json', 'lua', 'markdown',
        'python', 'r', 'tql', 'typescript', 'typescriptreact', 'yaml',
      },
      callback = function()
        vim.treesitter.start()
      end,
    })

    vim.filetype.add({ extension = { tql = 'tql' } })
  end,
}
