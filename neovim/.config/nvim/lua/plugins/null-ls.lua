-- Expand LSP experience to non-LSP-grade linters.
return {
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
