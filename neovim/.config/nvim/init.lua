-- Appearance.
vim.o.laststatus = 3 -- Global statusline
vim.wo.signcolumn = 'number' -- Gutter on the left

-- Generic UX.
vim.o.background = 'dark' -- Colorscheme
vim.o.clipboard = 'unnamedplus' -- Use system pastebuffer
vim.o.completeopt = 'menuone,noinsert' -- Consistent completion prompting
vim.o.inccommand = 'nosplit' -- Incremental live completion
vim.o.mouse = 'a' -- Enable mouse mode
vim.o.termguicolors = true -- Enables 24-bit RGB colors in TUI

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

-- Bootstrap Lazy
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup('plugins')
