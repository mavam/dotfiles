-- Remap space as leader key.
vim.api.nvim_set_keymap('', ',', '<Nop>', { noremap = true, silent = true })
vim.g.mapleader = ','
vim.g.maplocalleader = ','

-- Use system pastebuffer.
vim.o.clipboard = 'unnamedplus'

-- Global statusline.
vim.o.laststatus = 3

-- No need for swapfiles nowadays.
vim.o.backup = false
vim.o.writebackup = false
vim.o.swapfile = false

-- Do not save when switching buffers.
vim.o.hidden = true

-- Enable mouse mode.
vim.o.mouse = 'a'

-- Incremental live completion.
vim.o.inccommand = 'nosplit'

-- Set highlight on search.
vim.o.hlsearch = false

-- Case insensitive searching unless explicitly using /C or using at least one
-- capital letter in search.
vim.o.ignorecase = true
vim.o.smartcase = true

-- Decrease update time.
vim.o.updatetime = 250
vim.wo.signcolumn = 'yes'

-- Deal with word wrapping automatically for j/k.
vim.api.nvim_set_keymap('n', 'k', "v:count == 0 ? 'gk' : 'k'", {
  expr = true,
  noremap = true,
  silent = true,
})
vim.api.nvim_set_keymap('n', 'j', "v:count == 0 ? 'gj' : 'j'", {
  expr = true,
  noremap = true,
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

return require('packer').startup(function(use)
  -- Package manager.
  use 'wbthomason/packer.nvim'

  -- Enable repeating supporting plugin maps with `.`.
  use 'tpope/vim-repeat'

  -- Heuristically set buffer options.
  use 'tpope/vim-sleuth'

  -- Git integration
  use 'tpope/vim-fugitive'

  -- Automatic dark mode switching on macOS.
  use {
    'f-person/auto-dark-mode.nvim',
    config = function()
      local auto_dark_mode = require('auto-dark-mode')
      auto_dark_mode.setup{
        update_interval = 1000,
        set_dark_mode = function()
          vim.api.nvim_set_option('background', 'dark')
          -- vim.cmd('colorscheme gruvbox')
        end,
        set_light_mode = function()
          vim.api.nvim_set_option('background', 'light')
          -- vim.cmd('colorscheme gruvbox')
        end,
      }
      auto_dark_mode.init()
    end,
  }

  -- UI to select things (files, grep results, open buffers...)
  use {
    'nvim-telescope/telescope.nvim',
    requires = {
      { 'nvim-lua/popup.nvim' },
      { 'nvim-lua/plenary.nvim' }
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
      vim.api.nvim_set_keymap('n', '<Tab>', [[<cmd>lua require('telescope.builtin').buffers({sort_lastused = true, require('telescope.themes').get_ivy({})})<CR>]], { noremap = true, silent = true })
      vim.api.nvim_set_keymap('n', '<S-Tab>', [[<cmd>lua require('telescope.builtin').git_files(require('telescope.themes').get_ivy({}))<CR>]], { noremap = true, silent = true })
      vim.api.nvim_set_keymap('n', '<leader>sf', [[<cmd>lua require('telescope.builtin').find_files({previewer = false})<CR>]], { noremap = true, silent = true })
      vim.api.nvim_set_keymap('n', '<leader>sb', [[<cmd>lua require('telescope.builtin').current_buffer_fuzzy_find()<CR>]], { noremap = true, silent = true })
      vim.api.nvim_set_keymap('n', '<leader>sh', [[<cmd>lua require('telescope.builtin').help_tags()<CR>]], { noremap = true, silent = true })
      vim.api.nvim_set_keymap('n', '<leader>st', [[<cmd>lua require('telescope.builtin').tags()<CR>]], { noremap = true, silent = true })
      vim.api.nvim_set_keymap('n', '<leader>sd', [[<cmd>lua require('telescope.builtin').grep_string()<CR>]], { noremap = true, silent = true })
      vim.api.nvim_set_keymap('n', '<leader>sp', [[<cmd>lua require('telescope.builtin').live_grep()<CR>]], { noremap = true, silent = true })
      vim.api.nvim_set_keymap('n', '<leader>so', [[<cmd>lua require('telescope.builtin').tags{ only_current_buffer = true }<CR>]], { noremap = true, silent = true })
      vim.api.nvim_set_keymap('n', '<leader>?', [[<cmd>lua require('telescope.builtin').oldfiles()<CR>]], { noremap = true, silent = true })
    end
  }

  -- TreeSitter integration, and additional textobjects for it.
  use {
    'nvim-treesitter/nvim-treesitter',
    config = function()
      require'nvim-treesitter.configs'.setup {
        ensure_installed = {
          'bash';
          'c';
          'comment';
          'cpp';
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

  use {
    'nvim-treesitter/nvim-treesitter-textobjects',
    requires = {
      'nvim-treesitter/nvim-treesitter'
    }
  }

  -- Add git related info in the signs columns and popups
  use {
    'lewis6991/gitsigns.nvim',
    requires = {
      'nvim-lua/plenary.nvim'
    },
    config = function()
      require'gitsigns'.setup {
        signs = {
          add = { hl = 'GitGutterAdd', text = '+' },
          change = { hl = 'GitGutterChange', text = '~' },
          delete = { hl = 'GitGutterDelete', text = '_' },
          topdelete = { hl = 'GitGutterDelete', text = '‾' },
          changedelete = { hl = 'GitGutterChange', text = '~' },
        },
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

  -- Enhanced terminal integration for Vim
  use {
    'wincent/terminus'
  }

  -- Dark colorscheme inspired by the colors of the famous painting by Katsushika Hokusai.
  -- High Contrast & Vivid Color Scheme based on Monokai Pro.
  -- use {
  --   'ellisonleao/gruvbox.nvim',
  --   requires = {'rktjmp/lush.nvim'},
  --   config = function()
  --     vim.o.termguicolors = true
  --     vim.cmd 'colorscheme gruvbox'
  --   end
  -- }
  -- Collection of configurations for built-in LSP client.
  use {
    'neovim/nvim-lspconfig',
    config = function()
      local on_attach = function(_, bufnr)
	-- TODO: Can we express this using vim.o?
	vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")
	local opts = { noremap = true, silent = true }
        vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
        vim.api.nvim_buf_set_keymap(bufnr, 'v', '<leader>ca', '<cmd>lua vim.lsp.buf.range_code_action()<CR>', opts)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>so', [[<cmd>lua require'telescope.builtin'.lsp_document_symbols(require'telescope.themes'.get_ivy({ winblend = 10 }))<CR>]], opts)
        vim.cmd [[ command! Format execute 'lua vim.lsp.buf.formatting()' ]]
      end
      require'lspconfig'.clangd.setup {
        init_options = {
	  clandFileStatus = true
	},
	on_attach = on_attach
      }
    end
  }

  -- Standalone UI for nvim-lsp progress. Eye candy for the impatient.
  -- use {
  --   'j-hui/fidget.nvim',
  --   config = function()
  --     require"fidget".setup{}
  --   end
  -- }

  -- Autocompletion plugin.
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
      -- Map tab to the above tab complete functiones
      vim.api.nvim_set_keymap('i', '<Tab>', 'v:lua.tab_complete()', { expr = true })
      vim.api.nvim_set_keymap('s', '<Tab>', 'v:lua.tab_complete()', { expr = true })
      vim.api.nvim_set_keymap('i', '<S-Tab>', 'v:lua.s_tab_complete()', { expr = true })
      vim.api.nvim_set_keymap('s', '<S-Tab>', 'v:lua.s_tab_complete()', { expr = true })
      -- Map compe confirm and complete functions
      vim.api.nvim_set_keymap('i', '<cr>', 'compe#confirm("<cr>")', { expr = true })
      vim.api.nvim_set_keymap('i', '<c-space>', 'compe#complete()', { expr = true })
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

  -- Automatically set up your configuration after cloning packer.nvim
  -- Put this at the end after all plugins
  if packer_bootstrap then
    require('packer').sync()
  end
end)

