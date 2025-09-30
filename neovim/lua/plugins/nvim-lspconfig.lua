-- Language server configurations.
return {
  'neovim/nvim-lspconfig',
  config = function()
    local function configure(name, opts)
      if opts then
        vim.lsp.config(name, opts)
      end
      vim.lsp.enable(name)
    end

    -- C & C++
    configure('clangd', {
      init_options = {
        clangdFileStatus = true
      },
      on_attach = custom_on_attach
    })

    -- Python
    configure('pyright', {
      on_attach = custom_on_attach,
      on_init = function(client)
        client.config.settings = client.config.settings or {}
        client.config.settings.python = client.config.settings.python or {}
        client.config.settings.python.pythonPath = get_python_path(client.config.root_dir)
      end
    })

    -- R
    configure('r_language_server', {
      on_attach = custom_on_attach
    })

    -- Svelte
    configure('svelte', {
      on_attach = custom_on_attach
    })
  end
}
