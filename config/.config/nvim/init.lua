-- Appearance.
vim.o.laststatus = 3 -- Global statusline.
vim.wo.signcolumn = 'number' -- Gutter on the left

-- Generic UX.
vim.o.mouse = 'a' -- Enable mouse mode.
vim.o.clipboard = 'unnamedplus' -- Use system pastebuffer.
vim.o.inccommand = 'nosplit' -- Incremental live completion.

-- Search UX.
vim.o.hlsearch = true -- Set highlight on search.
vim.o.ignorecase = true -- Case-insensitive search.
vim.o.smartcase = true  -- Override ignorecase when we have capital letters.

-- Tab/space defaults, overriden by vim-sleuth.
vim.o.expandtab = true
vim.o.tabstop = 2
vim.o.softtabstop = 2
vim.o.shiftwidth = 2
vim.o.textwidth = 80

-- No swapfiles.
vim.o.backup = false
vim.o.writebackup = false
vim.o.swapfile = false
vim.o.hidden = true -- Do not save when switching buffers.

-- Remap space as leader key.
vim.keymap.set('', ',', '<Nop>')
vim.g.mapleader = ','
vim.g.maplocalleader = ','

-- Deal with word wrapping automatically for j/k.
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", {
  expr = true,
  silent = true,
})
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", {
  expr = true,
  silent = true,
})

-- Highlight on yank.
vim.api.nvim_exec([[
    augroup YankHighlight
      autocmd!
      autocmd TextYankPost * silent! lua vim.highlight.on_yank()
    augroup end
  ]],
  false)

-- Highlight on yank.
vim.api.nvim_exec([[
    set makeprg=cmake\ --build\ build
  ]],
  false)

-- Bootstrap Packer
local install_path = vim.fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
  packer_bootstrap = vim.fn.system({
    'git',
    'clone',
    '--depth',
    '1',
    'https://github.com/wbthomason/packer.nvim',
    install_path
  })
end

-- Shared on_attach handler for language server tooling.
custom_on_attach = function(client, bufnr)
  vim.api.nvim_buf_set_option(bufnr, 'tagfunc', 'v:lua.vim.lsp.tagfunc')
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
  vim.api.nvim_buf_set_option(bufnr, 'formatexpr', 'v:lua.vim.lsp.formatexpr()')
  -- Setup bindings.
  local opts = function(hint)
    return { buffer = bufnr, silent = true, desc = hint }
  end
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts("Go to declaration"))
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts("Go to definition"))
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts("LSP hover"))
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts("Go to implementation"))
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts("Show signature help"))
  --vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, opts)
  --vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, opts)
  --vim.keymap.set('n', '<leader>wl', vim.lsp.buf.list_workspace_folders, opts)
  --vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, opts)
  --vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts("Go to references"))
  --vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
  --vim.keymap.set('v', '<leader>ca', vim.lsp.buf.range_code_action, opts)
  --vim.keymap.set('n', '<leader>e', vim.lsp.diagnostic.show_line_diagnostics, opts)
  vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts("Go to previous diagnostic"))
  vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts("Go to next diagnostic"))
  --vim.keymap.set('n', 'gl', vim.lsp.diagnostic.open_float, opts)
  --vim.keymap.set('n', '<leader>q', vim.lsp.diagnostic.set_loclist, opts)

  if client.server_capabilities.documentFormattingProvider then
    vim.keymap.set('n', '<leader>f', vim.lsp.buf.format, opts("Format buffer"))
  end

  if client.server_capabilities.documentRangeFormattingProvider then
    vim.keymap.set('v', '<leader>f', vim.lsp.buf.range_formatting, opts("Format range"))
  end
end

return require('packer').startup(function(use)
  -- Package manager.
  use 'wbthomason/packer.nvim'

  -- Enable repeating supporting plugin maps with `.`.
  use 'tpope/vim-repeat'

  -- Heuristically set buffer options.
  use 'tpope/vim-sleuth'

  -- Git integration
  use 'tpope/vim-fugitive'

  -- Facilitate whitespace management
  use 'ntpeters/vim-better-whitespace'

  -- Automatic dark mode switching on macOS.
  use {
    'f-person/auto-dark-mode.nvim',
    config = function()
      local auto_dark_mode = require('auto-dark-mode')
      auto_dark_mode.setup{
        update_interval = 3000,
        set_dark_mode = function()
          vim.api.nvim_set_option('background', 'dark')
        end,
        set_light_mode = function()
          vim.api.nvim_set_option('background', 'light')
        end,
      }
      auto_dark_mode.init()
    end,
  }

  -- UI to select things (files, grep results, open buffers...)
  use {
    'nvim-telescope/telescope.nvim',
    requires = {
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

  -- TreeSitter integration, and additional textobjects for it.
  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate', -- recommended by nvim-bqf
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

  -- Syntax aware text-objects, select, move, swap, and peek support.
  use {
    'nvim-treesitter/nvim-treesitter-textobjects',
    requires = 'nvim-treesitter/nvim-treesitter'
  }

  -- Better QuickFix
  use 'kevinhwang91/nvim-bqf'

  -- Make working with a filesystem tree a breeze.
  use {
    'kyazdani42/nvim-tree.lua',
    requires = 'kyazdani42/nvim-web-devicons',
    config = function()
      require'nvim-tree'.setup {
      }
      -- mnemonic: 't' for filesystem 'T'ree
      vim.keymap.set('n', '<leader>t', ':NvimTreeToggle<Cr>', { silent = true })
    end
  }

  -- Add git related info in the signs columns and popups
  use {
    'lewis6991/gitsigns.nvim',
    requires = {
      'nvim-lua/plenary.nvim'
    },
    config = function()
      require'gitsigns'.setup {
        current_line_blame = true
      }
    end
  }

  -- Display a character as the virtual column.
  use {
    'lukas-reineke/virt-column.nvim',
    config = function()
      require('virt-column').setup()
    end,
  }

  -- Horiontal highlights for headlines.
  use {
    'lukas-reineke/headlines.nvim',
    config = function()
      require('headlines').setup()
    end,
  }

  -- Colorscheme.
  use {
    'rebelot/kanagawa.nvim',
    config = function()
      require('kanagawa').setup{
        undercurl = true,           -- enable undercurls
        commentStyle = "italic",
        functionStyle = "NONE",
        keywordStyle = "italic",
        statementStyle = "bold",
        typeStyle = "NONE",
        variablebuiltinStyle = "italic",
        specialReturn = true,       -- special highlight for the return keyword
        specialException = true,    -- special highlight for exception handling keywords
        transparent = true,         -- do not set background color
        dimInactive = false,        -- dim inactive window `:h hl-NormalNC`
        globalStatus = true,
        colors = {},
        overrides = {},
      }
      vim.o.termguicolors = true
      -- vim.cmd 'highlight WinSeparator NONE'
      vim.cmd 'colorscheme kanagawa'
    end
  }

  -- Language server configurations.
  use {
    'neovim/nvim-lspconfig',
    config = function()
      -- C & C++
      require('lspconfig').clangd.setup {
        init_options = {
          clangdFileStatus = true
        },
        on_attach = custom_on_attach
      }
      -- Python
      require('lspconfig').pyright.setup {
        on_attach = custom_on_attach
      }
      -- R
      require('lspconfig').r_language_server.setup {
        on_attach = custom_on_attach
      }
    end
  }

  -- Expand LSP experience to non-LSP-grade linters.
  use {
    "jose-elias-alvarez/null-ls.nvim",
    config = function()
      require("null-ls").setup({
        sources = {
          require("null-ls").builtins.formatting.stylua,
          require("null-ls").builtins.diagnostics.markdownlint,
          require("null-ls").builtins.diagnostics.shellcheck,
        },
        on_attach = custom_on_attach
      })
    end
  }

  -- Autocompletion plugin.
  -- TODO: migrate to nvim-cmp, nvim-compe is deprecated.
  use {
    'hrsh7th/nvim-compe',
    config = function()
      vim.o.completeopt = 'menuone,noinsert'
      require('compe').setup {
        source = {
          path = true,
          nvim_lsp = true,
          luasnip = false,
          buffer = false,
          calc = false,
          nvim_lua = false,
          vsnip = false,
          ultisnips = false,
        },
      }
      local check_back_space = function()
        local col = vim.fn.col '.' - 1
        if col == 0 or vim.fn.getline('.'):sub(col, col):match '%s' then
          return true
        else
          return false
        end
      end
      _G.tab_complete = function()
        if vim.fn.pumvisible() == 1 then
          return vim.api.nvim_replace_termcodes('<C-n>', true, true, true)
        -- elseif luasnip.expand_or_jumpable() then
        --  return t '<Plug>luasnip-expand-or-jump'
        elseif check_back_space() then
          return vim.api.nvim_replace_termcodes('<Tab>', true, true, true)
        else
          return vim.fn['compe#complete']()
        end
      end
      _G.s_tab_complete = function()
        if vim.fn.pumvisible() == 1 then
	  return vim.api.nvim_replace_termcodes('<C-p>', true, true, true)
        -- elseif luasnip.jumpable(-1) then
        --   return t '<Plug>luasnip-jump-prev'
        else
	  return vim.api.nvim_replace_termcodes('<S-Tab>', true, true, true)
        end
      end
      -- Map tab to the above tab complete functions
      vim.keymap.set('i', '<Tab>', 'v:lua.tab_complete()', { expr = true })
      vim.keymap.set('s', '<Tab>', 'v:lua.tab_complete()', { expr = true })
      vim.keymap.set('i', '<S-Tab>', 'v:lua.s_tab_complete()', { expr = true })
      vim.keymap.set('s', '<S-Tab>', 'v:lua.s_tab_complete()', { expr = true })
      -- Map compe confirm and complete functions
      vim.keymap.set('i', '<cr>', 'compe#confirm("<cr>")', { expr = true })
      vim.keymap.set('i', '<c-space>', 'compe#complete()', { expr = true })
    end
  }

  -- A neat status line.
  use {
    'nvim-lualine/lualine.nvim',
    requires = { 'kyazdani42/nvim-web-devicons', opt = true },
    config = function()
      require('lualine').setup()
    end
  }

  --- R integration.
  use {
    'jalvesaq/Nvim-R',
    branch = 'master',
    config = function()
      vim.g.R_assign = 0
    end
  }

  -- Automatically set up your configuration after cloning packer.nvim
  -- Put this at the end after all plugins
  if packer_bootstrap then
    require('packer').sync()
  end
end)
