--
-- LSP
--

require('fidget').setup()
require("symbols-outline").setup({
  autofold_depth = 2
})
vim.cmd([[
  nnoremap <silent><leader>l <cmd>SymbolsOutline<cr>
]])
require('inc_rename').setup()

vim.cmd([[
  nnoremap <silent><leader>ca <cmd>CodeActionMenu<cr>
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

local function attach_keymaps(client, bufnr)
  local bopts = { noremap = true, silent = true, buffer = bufnr }

  vim.keymap.set('n', '<leader>cr', ':IncRename ', bopts)
  vim.keymap.set('n', '<leader>cf', function() vim.lsp.buf.format({ bufnr = bufnr }) end, bopts)
  vim.keymap.set('n', 'gd', '<cmd>Telescope lsp_definitions<cr>', bopts)
  vim.keymap.set('n', 'gt', '<cmd>Telescope lsp_type_definitions<cr>', bopts)
  vim.keymap.set('n', 'gi', '<cmd>Telescope lsp_implementations<cr>', bopts)
  vim.keymap.set('n', 'gr', '<cmd>Telescope lsp_references<cr>', bopts)
  vim.keymap.set('n', 'gc', '<cmd>Telescope lsp_incoming_calls<cr>', bopts)
  vim.keymap.set('n', 'go', '<cmd>Telescope lsp_outgoing_calls<cr>', bopts)
  vim.keymap.set('', 'K', vim.lsp.buf.hover, bopts)
end

local function on_attach(client, bufnr)
  format_on_save(client, bufnr)
  attach_keymaps(client, bufnr)
end

local capabilities = require('cmp_nvim_lsp').default_capabilities()
-- for nvim-ufo folding.
capabilities.textDocument.foldingRange = {
  dynamicRegistration = false,
  lineFoldingOnly = true
}

lspconfig.rnix.setup {
  capabilities = capabilities,
  on_attach = function(client, bufnr)
    -- formatting done by alejandra from null-ls
    client.server_capabilities.documentFormattingProvider = false
    attach_keymaps(client, bufnr)
  end
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
local rt = require('rust-tools')
rt.setup({
  server = {
    on_attach = function(client, bufnr)
      on_attach(client, bufnr)
      local bopts = { noremap = true, silent = true, buffer = bufnr }
      vim.keymap.set('n', '<C-space>', rt.hover_actions.hover_actions, bopts)
      -- keymap('K', rt.hover_range.hover_range, bopts)
    end
  },
  tools = {
    hover_actions = {
      auto_focus = true,
    },
  },
  -- https://github.com/simrat39/rust-tools.nvim/wiki/Debugging#codelldb-a-better-debugging-experience
  dap = {
    adapter = (function()
      local extension_path = vim.fn.environ()["VSCODE_EXTENSION_LLDB"]
      local codelldb_path = extension_path .. '/adapter/codelldb'
      local liblldb_path = extension_path .. '/lldb/lib/liblldb.so'
      return require('rust-tools.dap').get_codelldb_adapter(codelldb_path, liblldb_path)
    end)()
  }
})
require('crates').setup { null_ls = { enabled = true } }

require('typescript').setup({
  server = {
    on_attach = on_attach
  }
})

local null_ls = require('null-ls')
null_ls.setup({
  sources = {
    -- Nix
    null_ls.builtins.formatting.alejandra,
    null_ls.builtins.diagnostics.deadnix,
    null_ls.builtins.diagnostics.statix,
    -- Shell
    null_ls.builtins.code_actions.shellcheck,
    null_ls.builtins.diagnostics.shellcheck,
    null_ls.builtins.formatting.shfmt,
    -- Spelling
    null_ls.builtins.diagnostics.codespell.with({
      extra_args = { "--builtin=clear,informal" }
    }),
    --
    null_ls.builtins.formatting.prettier_d_slim, -- HTML/JS/Markdown/... formatting
    null_ls.builtins.formatting.taplo, -- TOML
    null_ls.builtins.diagnostics.clang_check,
  },
  on_attach = on_attach
})
