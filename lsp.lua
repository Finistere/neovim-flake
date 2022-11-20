--
-- LSP
--

require('lsp_signature').setup()
require('fidget').setup()
require('inc_rename').setup()

require('nvim-lightbulb').setup({ autocmd = { enabled = true } })

vim.cmd([[
  nnoremap <silent><leader>ca <cmd>CodeActionMenu<cr>
]])

require('trouble').setup({
  padding = false,
  auto_jump = { 'lsp_definitions', 'lsp_type_definitions' },
  action_keys = {
    jump_close = { '<cr>' },
    jump = { "o", "<tab>" }
  }
})
vim.cmd([[
  nnoremap <silent><leader>xx <cmd>TroubleToggle<cr>
  nnoremap <silent><leader>xw <cmd>TroubleToggle workspace_diagnostics<cr>
  nnoremap <silent><leader>xd <cmd>TroubleToggle document_diagnostics<cr>
  nnoremap <silent><leader>xq <cmd>TroubleToggle quickfix<cr>
  nnoremap <silent><leader>xl <cmd>TroubleToggle loclist<cr>
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

  keymap('<leader>cr', ':IncRename ', bopts)
  keymap('<leader>cf', function() vim.lsp.buf.format({ bufnr = bufnr }) end, bopts)

  keymap('gd', '<cmd>Telescope lsp_definitions<cr>', bopts)
  keymap('gt', '<cmd>Telescope lsp_type_definitions<cr>', bopts)
  keymap('gi', '<cmd>Telescope lsp_implementations<cr>', bopts)
  keymap('gr', '<cmd>Telescope lsp_references<cr>', bopts)
  keymap('gc', '<cmd>Telescope lsp_incoming_calls<cr>', bopts)
  keymap('go', '<cmd>Telescope lsp_outgoing_calls<cr>', bopts)
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
    -- Nix
    null_ls.builtins.formatting.alejandra,
    null_ls.builtins.diagnostics.deadnix,
    null_ls.builtins.diagnostics.staticx,
    -- Shell
    null_ls.builtins.code_actions.shellcheck,
    null_ls.builtins.formatting.shfmt
  },
  on_attach = on_attach
})

require('crates').setup { null_ls = { enabled = true } }
