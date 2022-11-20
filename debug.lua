--
-- Debug
--
vim.cmd([[
  nnoremap <silent> <leader>b <cmd>lua require'dap'.toggle_breakpoint()<cr>
  nnoremap <silent> <leader>B <cmd>lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<cr>
]])

local dap = require('dap')
local dapui = require('dapui')

require('nvim-dap-virtual-text').setup {}

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
