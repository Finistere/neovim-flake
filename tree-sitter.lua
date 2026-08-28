--
-- Treesitter
--
local minimal_profile = vim.g.minimal_profile == true

vim.api.nvim_create_autocmd('FileType', {
  pattern = '*',
  group = vim.api.nvim_create_augroup('user_plugin_nvim_treesitter', {}),
  callback = function(args)
    local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
    if not lang or not vim.treesitter.language.add(lang) then return end

    -- syntax highlighting, provided by Neovim
    vim.treesitter.start(args.buf, lang)
    -- folds, provided by Neovim
    vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    vim.wo.foldmethod = 'expr'
    -- indentation, provided by nvim-treesitter
    vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})

require('treesitter-context').setup {
  enable = true,
}

vim.filetype.add({ extension = { mdx = 'mdx' } })
vim.treesitter.language.register('markdown', 'mdx')

if not minimal_profile then
  -- Had to create `.config/mvim`
  require('tree-sitter-language-injection').setup {}
end
