--
-- UI
--

require('nvim-web-devicons').setup()

require('nvim-tree').setup({
  diagnostics = {
    enable = true,
    show_on_dirs = true,
  },
  filters = {
    custom = { "^\\.git$" }
  }
})
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

require('bufferline').setup({
  options = {
    show_close_icon = false,
    show_buffer_close_icons = false,
    separator_style = 'slant',
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
  nnoremap <silent><leader>s <cmd>BufferLinePick<cr>
  nnoremap <silent><leader>d <cmd>BufferLinePickClose<cr>
  nnoremap <silent><leader>1 <cmd>BufferLineGoToBuffer 1<cr>
  nnoremap <silent><leader>2 <cmd>BufferLineGoToBuffer 2<cr>
  nnoremap <silent><leader>3 <cmd>BufferLineGoToBuffer 3<cr>
  nnoremap <silent><leader>4 <cmd>BufferLineGoToBuffer 4<cr>
  nnoremap <silent><leader>5 <cmd>BufferLineGoToBuffer 5<cr>
  nnoremap <silent><leader>6 <cmd>BufferLineGoToBuffer 6<cr>
  nnoremap <silent><leader>7 <cmd>BufferLineGoToBuffer 7<cr>
  nnoremap <silent><leader>8 <cmd>BufferLineGoToBuffer 8<cr>
  nnoremap <silent><leader>9 <cmd>BufferLineGoToBuffer 9<cr>
  nnoremap <silent><A-left> <cmd>BufferLineCyclePrev<cr>
  nnoremap <silent><A-right> <cmd>BufferLineCycleNext<cr>
  nnoremap <silent><S-left> <cmd>BufferLineMovePrev<cr>
  nnoremap <silent><S-right> <cmd>BufferLineMoveNext<cr>
]])

require('lualine').setup()

require('neotest').setup({
  adapters = {
    require("neotest-rust")
  }
})


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


--
-- Debug
--
require('dapui').setup()
require('nvim-dap-virtual-text').setup()
