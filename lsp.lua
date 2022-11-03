--
-- LSP
--

require('lsp_signature').setup()
require('fidget').setup()
require('lspsaga').setup({
  finder_action_keys = {
    open = '<cr>'
  }
})
require('inc_rename').setup()

require('nvim-lightbulb').setup({ autocmd = { enabled = true } })

vim.cmd([[
  nnoremap <silent><leader>ca <cmd>CodeActionMenu<cr>
]])

require('trouble').setup({
  padding = false,
  auto_jump = { 'lsp_definitions', 'lsp_type_definitions' },
})
vim.cmd([[
  nnoremap <silent><leader>xx <cmd>TroubleToggle<cr>
  nnoremap <silent><leader>xw <cmd>TroubleToggle workspace_diagnostics<cr>
  nnoremap <silent><leader>xd <cmd>TroubleToggle document_diagnostics<cr>
  nnoremap <silent><leader>xq <cmd>TroubleToggle quickfix<cr>
  nnoremap <silent><leader>xl <cmd>TroubleToggle loclist<cr>
]])

require("nvim-semantic-tokens").setup {
  preset = "default",
  -- highlighters is a list of modules following the interface of nvim-semantic-tokens.table-highlighter or
  -- function with the signature: highlight_token(ctx, token, highlight) where
  --        ctx (as defined in :h lsp-handler)
  --        token  (as defined in :h vim.lsp.semantic_tokens.on_full())
  --        highlight (a helper function that you can call (also multiple times) with the determined highlight group(s) as the only parameter)
  highlighters = { require 'nvim-semantic-tokens.table-highlighter' }
}

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
  -- keymap('<leader>cr', require('lspsaga.rename').rename, bopts)
  keymap('<leader>cr', ':IncRename ', bopts)
  keymap('<leader>cf', function() vim.lsp.buf.format({ bufnr = bufnr }) end, bopts)

  keymap('gh', require('lspsaga.provider').lsp_finder, bopts)
  keymap('gD', vim.lsp.buf.declaration, bopts)
  keymap('gd', '<cmd>TroubleToggle lsp_definitions<cr>', bopts)
  keymap('gt', '<cmd>TroubleToggle lsp_type_definitions<cr>', bopts)
  keymap('gr', '<cmd>TroubleToggle lsp_references<cr>', bopts)
  keymap('gi', '<cmd>TroubleToggle lsp_implementations<cr>', bopts)

  keymap('H', vim.lsp.buf.hover, bopts)

  local caps = client.server_capabilities
  if caps.semanticTokensProvider and caps.semanticTokensProvider.full then
    local augroup = vim.api.nvim_create_augroup("SemanticTokens", {})
    vim.api.nvim_create_autocmd("TextChanged", {
      group = augroup,
      buffer = bufnr,
      callback = function()
        vim.lsp.buf.semantic_tokens_full()
      end,
    })
    -- fire it first time on load as well
    vim.lsp.buf.semantic_tokens_full()
  end
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
  },
  tools = {
    hover_actions = {
      auto_focus = true,
    },
  },
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

require('crates').setup { null_ls = { enabled = true } }
