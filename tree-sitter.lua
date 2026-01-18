--
-- Treesitter
--

vim.api.nvim_create_autocmd('FileType', {
  pattern = vim.g.treesitter_grammars, -- from Nix
  group = vim.api.nvim_create_augroup("user_plugin_nvim_treesitter", {}),
  callback = function(args)
    -- syntax highlighting, provided by Neovim
    vim.treesitter.start()
    -- folds, provided by Neovim
    vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    vim.wo.foldmethod = 'expr'
    -- indentation, provided by nvim-treesitter
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    -- end
  end,
})

require('treesitter-context').setup {
  enable = true,
}

vim.filetype.add({ extension = { mdx = 'mdx' } })
vim.treesitter.language.register('markdown', 'mdx')

-- Had to create `.config/mvim`
require("tree-sitter-language-injection").setup {}
