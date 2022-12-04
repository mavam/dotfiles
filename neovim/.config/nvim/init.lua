-- Appearance.
vim.o.laststatus = 3 -- Global statusline.
vim.wo.signcolumn = 'number' -- Gutter on the left

-- Generic UX.
vim.o.mouse = 'a' -- Enable mouse mode.
vim.o.clipboard = 'unnamedplus' -- Use system pastebuffer.
vim.o.inccommand = 'nosplit' -- Incremental live completion.
vim.o.completeopt = 'menuone,noinsert' -- Consistent completion prompting.

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

-- Utility function to find the Python path.
-- Detail: https://github.com/neovim/nvim-lspconfig/issues/500#issuecomment-876700701
get_python_path = function(workspace)
  local util = require('lspconfig/util')
  -- Use activated virtualenv.
  if vim.env.VIRTUAL_ENV then
    return util.path.join(vim.env.VIRTUAL_ENV, 'bin', 'python')
  end
  -- Find and use virtualenv from pipenv in workspace directory.
  local match = vim.fn.glob(util.path.join(workspace, 'Pipfile'))
  if match ~= '' then
    local venv = vim.fn.trim(vim.fn.system('PIPENV_PIPFILE=' .. match .. ' pipenv --venv'))
    return util.path.join(venv, 'bin', 'python')
  end
  -- Fallback to system Python.
  return vim.fn.exepath('python3') or vim.fn.exepath('python') or 'python'
end

-- Shared on_attach handler for language server tooling.
custom_on_attach = function(client, bufnr)
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
  local opts = function(hint)
    return { buffer = bufnr, silent = true, desc = hint }
  end
  -- Buffer keymaps.
  vim.api.nvim_buf_set_option(bufnr, 'tagfunc', 'v:lua.vim.lsp.tagfunc')
  vim.api.nvim_buf_set_option(bufnr, 'formatexpr', 'v:lua.vim.lsp.formatexpr()')
  -- Capability-based keymaps.
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts("Go to declaration"))
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts("Go to definition"))
  vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, opts("Go to type definition"))
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts("LSP hover"))
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts("Go to implementation"))
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts("Show signature help"))
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts("Go to references"))
  vim.keymap.set('n', '<leader>f', vim.lsp.buf.format, opts("Format buffer"))
  vim.keymap.set('v', '<leader>f', vim.lsp.buf.format, opts("Format selection"))
  -- Universal keymaps.
  vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, opts("Show diagnostics"))
  vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts("Go to previous diagnostic"))
  vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts("Go to next diagnostic"))
  vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts("Perform code action"))
  vim.keymap.set('v', '<leader>ca', vim.lsp.buf.code_action, opts("Perform code action"))
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

  -- Colorscheme.
  use {
    'catppuccin/nvim',
    as = 'catppuccin',
    config = function()
      require('catppuccin').setup({
        background = {
          light = "latte",
          dark = "mocha",
        },
      })
      vim.o.background = 'dark'
      vim.o.termguicolors = true
      -- vim.cmd 'highlight WinSeparator NONE'
      vim.cmd.colorscheme 'catppuccin'
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
        on_attach = custom_on_attach,
        on_init = function(client)
            client.config.settings.python.pythonPath = get_python_path(client.config.root_dir)
        end
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
          require("null-ls").builtins.formatting.black,
          require("null-ls").builtins.formatting.stylua,
          require("null-ls").builtins.diagnostics.markdownlint,
          require("null-ls").builtins.diagnostics.shellcheck,
          --require("null-ls").builtins.diagnostics.vale,
        },
        on_attach = custom_on_attach
      })
    end
  }

  -- Incremental renaming while cursor is on LSP identifier.
  use {
    "smjonas/inc-rename.nvim",
    config = function()
      require("inc_rename").setup()
      vim.keymap.set("n", "<leader>r", ":IncRename ")
    end,
  }

  -- A neat status line.
  use {
    'nvim-lualine/lualine.nvim',
    requires = { 'kyazdani42/nvim-web-devicons', opt = true },
    config = function()
      require('lualine').setup()
    end
  }

  -- LaTeX integration.
  use {
    'lervag/vimtex',
    config = function()
      vim.g.tex_flavor = 'latex'
      -- Use Skim on macOS. This requires the following Sync settings:
      --   Preset: Custom
      --   Command: nvim
      --   Arguments: --headless -c "VimtexInverseSearch %line '%file'"
      vim.g.vimtex_view_method = 'skim'
      vim.g.vimtex_view_skim_sync = 1
      vim.g.vimtex_view_skim_activate = 1
    end
  }

  -- R integration.
  use {
    'jalvesaq/Nvim-R',
    branch = 'master',
    config = function()
      vim.g.R_assign = 0
    end
  }

  -- Pair programming neatness.
  use 'jbyuki/instant.nvim'

  -- Automatically set up your configuration after cloning packer.nvim
  -- Put this at the end after all plugins
  if packer_bootstrap then
    require('packer').sync()
  end
end)
