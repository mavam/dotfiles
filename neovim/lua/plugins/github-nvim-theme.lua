-- Colorscheme
return {
  'projekt0n/github-nvim-theme',
  as = 'github-theme',
  lazy = false,
  priority = 1000,
  config = function()
    local function disable_markdown_code_italics()
      for _, group in ipairs({
        '@markup.raw',
        '@markup.raw.markdown',
        '@markup.raw.markdown_inline',
        '@markup.raw.block',
        '@markup.raw.block.markdown',
      }) do
        local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
        hl.italic = false
        vim.api.nvim_set_hl(0, group, hl)
      end
    end

    require('github-theme').setup({
      options = {
        transparent = true,
      },
      groups = {
        all = {
          ['@markup.raw'] = { style = 'NONE' },
          ['@markup.raw.markdown'] = { style = 'NONE' },
          ['@markup.raw.markdown_inline'] = { style = 'NONE' },
          ['@markup.raw.block'] = { style = 'NONE' },
          ['@markup.raw.block.markdown'] = { style = 'NONE' },
        },
      },
    })

    vim.api.nvim_create_autocmd('ColorScheme', {
      group = vim.api.nvim_create_augroup('dotfiles-github-theme', { clear = true }),
      pattern = 'github_*',
      callback = disable_markdown_code_italics,
    })

    vim.cmd.colorscheme 'github_light'
    disable_markdown_code_italics()
  end,
}
