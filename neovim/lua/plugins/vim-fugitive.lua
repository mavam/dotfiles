-- Git integration
return {
  'tpope/vim-fugitive',
  config = function()
    vim.keymap.set('n', '<leader>gp', function()
      local term = vim.fn.input('Pickaxe search: ')
      if term ~= '' then
        vim.cmd('Git log -p -S ' .. vim.fn.shellescape(term))
      end
    end, { silent = true, desc = 'Git pickaxe search' })
  end
}

