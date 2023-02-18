-- Language server configurations.
return {
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
