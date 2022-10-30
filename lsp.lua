--
-- LSP
--

require("lsp_signature").setup()
require("lspsaga").setup({
  finder_action_keys = {
    open = "<cr>"
  }
})

require('nvim-lightbulb').setup({ autocmd = { enabled = true } })

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

local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
local function format_on_save(client, bufnr)
  if client.supports_method("textDocument/formatting") then
    vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = augroup,
      buffer = bufnr,
      callback = function()
        vim.lsp.buf.format({ bufnr = bufnr })
      end,
    })
  end
end

local function keymap(...) vim.keymap.set('n', ...) end

local function on_attach(client, bufnr)
  format_on_save(client, bufnr)

  local bopts = { noremap = true, silent = true, buffer = bufnr }

  -- TODO: preview_definition doesn't work & smart scrolling broken, not sure why...
  keymap('<leader>cr', require('lspsaga.rename').rename, bopts)
  keymap('<leader>cf', function() vim.lsp.buf.format({ bufnr = bufnr }) end, bopts)



  keymap('gh', require('lspsaga.provider').lsp_finder, bopts)
  keymap('gD', vim.lsp.buf.declaration, bopts)
  keymap('gd', vim.lsp.buf.definition, bopts)
  keymap('gt', vim.lsp.buf.type_definition, bopts)
  keymap('gr', vim.lsp.buf.references, bopts)
  keymap('gi', vim.lsp.buf.implementation, bopts)

  keymap('H', vim.lsp.buf.hover, bopts)
end

local capabilities = require('cmp_nvim_lsp').default_capabilities()

lspconfig.rnix.setup {
  capabilities = capabilities,
  on_attach = on_attach
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
  },
  on_attach = on_attach
}

-- Rust pre-configured by rust-tools
require('rust-tools').setup({
  server = {
    on_attach = on_attach
  }
})

local null_ls = require('null-ls')
null_ls.setup({
  sources = {
    null_ls.builtins.formatting.alejandra,
    null_ls.builtins.code_actions.shellcheck,
    null_ls.builtins.formatting.shfmt
  },
  on_attach = on_attach
})
