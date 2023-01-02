--
-- EDITOR
--
require('leap').add_default_mappings()

require('gitsigns').setup({
  current_line_blame_opts = {
    delay = 100,
  },
  on_attach = function(bufnr)
    local gs = package.loaded.gitsigns
    local bopts = { noremap = true, silent = true, buffer = bufnr }
    vim.keymap.set('n', '<leader>hb', function() gs.blame_line { full = true } end, bopts)
    vim.keymap.set('n', '<leader>tb', gs.toggle_current_line_blame, bopts)
  end
})
require('indent_blankline').setup({
  show_current_context = true,
  show_current_context_start = false
})
require('nvim-cursorline').setup()

require('Comment').setup()
require('range-highlight').setup()
require('todo-comments').setup()

-- nvim-ufo. Capabilities were also added to the LSP server.
vim.o.foldcolumn = '0' -- Whether to show folder column
vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
vim.o.foldlevelstart = 99
vim.o.foldenable = true
vim.keymap.set('n', 'zR', require('ufo').openAllFolds)
vim.keymap.set('n', 'zM', require('ufo').closeAllFolds)

require('ufo').setup()
