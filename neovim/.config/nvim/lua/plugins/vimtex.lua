-- LaTeX integration.
return {
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
