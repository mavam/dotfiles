-- TreeSitter integration, and additional textobjects for it.
return {
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate', -- recommended by nvim-bqf
  config = function()
    require'nvim-treesitter.configs'.setup {
      ensure_installed = {
        'bash';
        'c';
        'comment';
        'cpp';
        'fish';
        'json';
        'lua';
        'markdown';
        'python';
        'r';
        'yaml';
      },
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = true,
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
  end
}
