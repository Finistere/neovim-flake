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
