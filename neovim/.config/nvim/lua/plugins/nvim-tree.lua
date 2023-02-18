-- Make working with a filesystem tree a breeze.
return {
  'kyazdani42/nvim-tree.lua',
  dependencies = 'kyazdani42/nvim-web-devicons',
  config = function()
    require'nvim-tree'.setup {
    }
    -- mnemonic: 't' for filesystem 'T'ree
    vim.keymap.set('n', '<leader>t', ':NvimTreeToggle<Cr>', { silent = true })
  end
}
