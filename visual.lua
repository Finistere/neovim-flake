--
-- UI
--

require('nvim-web-devicons').setup()
require('nvim-tree').setup()
vim.cmd([[
  noremap <silent><C-n> <cmd>NvimTreeToggle<cr>
  noremap <silent><leader>tf <cmd>NvimTreeFocus<cr>
]])


local trouble = require('trouble.providers.telescope')
require('telescope').setup({
  defaults = {
    mappings = {
      i = { ["<C-t>"] = trouble.open_with_trouble },
      n = { ["<C-t>"] = trouble.open_with_trouble },
    }
  }
})
vim.cmd([[
  nnoremap <silent><leader>ff <cmd>Telescope find_files<cr>
  nnoremap <silent><leader>fg <cmd>Telescope live_grep<cr>
  nnoremap <silent><leader>fb <cmd>Telescope buffers<cr>
  nnoremap <silent><leader>fh <cmd>Telescope help_tags<cr>
]])

require('gitsigns').setup()
require('bufferline').setup({
  options = {
    show_close_icon = false,
    show_buffer_close_icons = false,
    separator_style = 'slant',
    numbers = function(opts)
      return string.format('%s|%s', opts.id, opts.raise(opts.ordinal))
    end,
    diagnostics = 'nvim_lsp',
    diagnostics_update_in_insert = true,
    diagnostics_indicator = function(count, level, diagnostics_dict, context)
      if context.buffer:current() then
        return ''
      end
      local icon = level:match("error") and " " or ""
      return " " .. icon .. count
    end,
  }
})
vim.cmd([[
  nnoremap <silent>gb <Cmd>BufferLinePick<CR>
  nnoremap <silent>gD <Cmd>BufferLinePickClose<CR>
  nnoremap <silent><leader>1 <Cmd>BufferLineGoToBuffer 1<CR>
  nnoremap <silent><leader>2 <Cmd>BufferLineGoToBuffer 2<CR>
  nnoremap <silent><leader>3 <Cmd>BufferLineGoToBuffer 3<CR>
  nnoremap <silent><leader>4 <Cmd>BufferLineGoToBuffer 4<CR>
  nnoremap <silent><leader>5 <Cmd>BufferLineGoToBuffer 5<CR>
  nnoremap <silent><leader>6 <Cmd>BufferLineGoToBuffer 6<CR>
  nnoremap <silent><leader>7 <Cmd>BufferLineGoToBuffer 7<CR>
  nnoremap <silent><leader>8 <Cmd>BufferLineGoToBuffer 8<CR>
  nnoremap <silent><leader>9 <Cmd>BufferLineGoToBuffer 9<CR>
  nnoremap <silent><leader>$ <Cmd>BufferLineGoToBuffer -1<CR>
]])

require('lualine').setup()


--
-- EDITOR
--

require('indent_blankline').setup({
  show_current_context = true,
  show_current_context_start = true
})
require('nvim-cursorline').setup()
