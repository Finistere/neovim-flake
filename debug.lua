--
-- Debug
--
vim.cmd([[
  nnoremap <silent> <leader>b <cmd>lua require'dap'.toggle_breakpoint()<cr>
  nnoremap <silent> <leader>B <cmd>lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<cr>
]])

local dap = require('dap')
dap.adapters.codelldb = {
  type = 'server',
  port = 13000,
  executable = {
    command = vim.g.codelldb_path,
    args = { "--port", "13000" },
  }
}
dap.configurations.rust = {
  {
    name = "Launch file",
    type = "codelldb",
    request = "launch",
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
    end,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
  },
}
vim.cmd([[
    nnoremap <silent> <Leader>dl <Cmd>lua require'dap'.run_last()<CR>
]])
local dapui = require('dapui')

require('nvim-dap-virtual-text').setup {}

dapui.setup()
dap.listeners.after.event_initialized["dapui_config"] = function()
  vim.cmd([[
    nnoremap <silent> <F16> <cmd>lua require'dap'.continue()<cr>
    nnoremap <silent> <F17> <cmd>lua require'dap'.step_into()<cr>
    nnoremap <silent> <F18> <cmd>lua require'dap'.step_over()<cr>
    nnoremap <silent> <F19> <cmd>lua require'dap'.step_out()<cr>
    nnoremap <silent> <F20> <cmd> lua require'dap'.terminate()<cr>

    nnoremap <silent> <F7> <cmd> lua require'dap'.down()<cr>
    nnoremap <silent> <F8> <cmd> lua require'dap'.up()<cr>

    nnoremap <silent> <Leader>dr <Cmd>lua require'dap'.repl.open()<CR>
  ]])
  dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
  dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = dap.listeners.before.event_terminated["dapui_config"]
