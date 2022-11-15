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
  nnoremap <silent><leader>fs <cmd>Telescope git_status<cr>
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
    name_formatter = function(buf)
      capture = string.match(buf.path, 'cargo/registry/.*/(.*)-%d+%.%d+%.%d+/src')
      if capture then
        return buf.name .. ' @ ' .. capture
      end
      return buf.name
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

-- ranger
vim.cmd([[
  " Hide ranger after picking a file
  let g:rnvimr_enable_picker = 1
  " Hide the files included in gitignore
  let g:rnvimr_hide_gitignore = 1
  " wipe buffers associated with deleted files
  let g:rnvimr_enable_bw = 1
  nnoremap <silent><leader>rt <cmd>RnvimrToggle<cr>
  tnoremap <silent><leader>r <cmd>RnvimrResize<cr>
]])


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
vim.cmd([[
  nnoremap <silent> <leader>b <cmd>lua require'dap'.toggle_breakpoint()<cr>
  nnoremap <silent> <leader>B <cmd>lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<cr>
]])

local dap = require('dap')
local dapui = require('dapui')

require('nvim-dap-virtual-text').setup()

dapui.setup()
dap.listeners.after.event_initialized["dapui_config"] = function()
  vim.cmd([[
    nnoremap <silent> <F6> <cmd>lua require'dap'.continue()<cr>
    nnoremap <silent> <F7> <cmd>lua require'dap'.step_into()<cr>
    nnoremap <silent> <F8> <cmd>lua require'dap'.step_over()<cr>
    nnoremap <silent> <F9> <cmd>lua require'dap'.step_out()<cr>
    nnoremap <silent> <F10> <cmd> lua require'dap'.terminate()<cr>
    nnoremap <silent> <S-F10> <cmd> lua require'dap'.run_last()<cr>

    nnoremap <silent> <F2> <cmd> lua require'dap'.down()<cr>
    nnoremap <silent> <F4> <cmd> lua require'dap'.up()<cr>
  ]])
  dapui.open()

end
dap.listeners.before.event_terminated["dapui_config"] = function()
  dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = dap.listeners.before.event_terminated["dapui_config"]
