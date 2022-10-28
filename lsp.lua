--
-- LSP
--

require("lsp_signature").setup()
require("lspsaga").setup()
vim.cmd([[
  nnoremap <silent> gr    <cmd>Lsspaga rename<cr>
  nnoremap <silent> K     <cmd>Lspsaga hover_doc<cr>
  nnoremap <silent> gd    <cmd>Lspsaga preview_definition<cr>
  nnoremap <silent> gh    <cmd>Lspsaga lsp_finder<cr>
  nnoremap <silent> <C-f> <cmd>lua require('lspsaga.action').smart_scroll_with_saga(1)<cr>
  nnoremap <silent> <C-b> <cmd>lua require('lspsaga.action').smart_scroll_with_saga(-1)<cr>
]])
require('nvim-lightbulb').setup({autocmd = {enabled = true}})

vim.cmd([[
  nnoremap <silent><leader>ca <cmd>CodeActionMenu<cr>
]])

require('trouble').setup()
vim.cmd([[
  nnoremap <silent><leader>xx <cmd>TroubleToggle<cr>
  nnoremap <silent><leader>xw <cmd>TroubleToggle workspace_diagnostics<cr>
  nnoremap <silent><leader>xd <cmd>TroubleToggle document_diagnostics<cr>
  nnoremap <silent><leader>xq <cmd>TroubleToggle quickfix<cr>
  nnoremap <silent><leader>xl <cmd>TroubleToggle loclist<cr>
  nnoremap <silent>gR <cmd>TroubleToggle lsp_references<cr>
]])


local lspconfig = require('lspconfig')
local capabilities = require('cmp_nvim_lsp').default_capabilities()

lspconfig.rnix.setup {
  capabilities = capabilities,
}

lspconfig.sumneko_lua.setup {
  capabilities = capabilities,
  settings = {
    Lua = {
      diagnostics = { globals = { 'vim' }, },
      runtime = { version = "LuaJIT", },
      workspace = {
        library = vim.api.nvim_get_runtime_file('', true),
      },
    }
  }
}

