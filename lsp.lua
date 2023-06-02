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

local nlspsettings = require("nlspsettings")
nlspsettings.setup({
  config_home = vim.fn.stdpath('config') .. '/nlsp-settings',
  local_settings_dir = ".nlsp-settings",
  local_settings_root_markers_fallback = { '.git' },
  append_default_schemas = true,
  loader = 'json'
})

local function attach_keymaps(client, bufnr)
  local bopts = { noremap = true, silent = true, buffer = bufnr }

  vim.keymap.set('n', '<leader>cr', ':IncRename ', bopts)
  -- Format file
  -- vim.keymap.set('n', '<leader>cf', function() vim.lsp.buf.format({ bufnr = bufnr }) end, bopts)
  vim.keymap.set(
    'n',
    '<leader>cf',
    function() vim.lsp.buf.code_action({ apply = true, context = { only = { "quickfix" } } }) end,
    bopts
  )
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
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
end

local capabilities = require('cmp_nvim_lsp').default_capabilities()
-- for nvim-ufo folding.
capabilities.textDocument.foldingRange = {
  dynamicRegistration = false,
  lineFoldingOnly = true
}
-- not sure if necesasry at global level. for jsonls/nlsp-settings
capabilities.textDocument.completion.completionItem.snippetSupport = true
lspconfig.jsonls.setup {
  capabilities = capabilities,
  on_attach = function(client, bufnr)
    -- formatting done by alejandra from null-ls
    client.server_capabilities.textDocument.completion.completionItem.snippetSupport = true;
    on_attach(client, bufnr)
  end
}

lspconfig.rnix.setup {
  capabilities = capabilities,
  on_attach = function(client, bufnr)
    -- formatting done by alejandra from null-ls
    client.server_capabilities.documentFormattingProvider = false
    attach_keymaps(client, bufnr)
  end
}

-- https://github.com/LuaLS/lua-language-server/issues/783
local runtime_path = vim.split(package.path, ';')
table.insert(runtime_path, 'lua/?.lua')
table.insert(runtime_path, 'lua/?/init.lua')
lspconfig.lua_ls.setup {
  capabilities = capabilities,
  settings = {
    Lua = {
      runtime = {
        -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
        version = 'LuaJIT',
        -- Setup your lua path
        path = runtime_path,
      },
      diagnostics = {
        -- Get the language server to recognize the `vim` global
        globals = { 'vim' },
      },
      workspace = {
        -- Make the server aware of Neovim runtime files
        library = vim.api.nvim_get_runtime_file('', true),
        checkThirdParty = false,
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
    end,
    settings = {
      cargo = {
        target = "wasm32-unknown-unknown"
      }
    }
  },
  tools = {
    hover_actions = {
      auto_focus = true,
    },
  },
  -- https://github.com/simrat39/rust-tools.nvim/wiki/Debugging#codelldb-a-better-debugging-experience
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
    null_ls.builtins.formatting.shfmt.with({
      extra_args = { "--indent=4" }
    }),
    -- Spelling
    null_ls.builtins.diagnostics.codespell.with({
      extra_args = { "--builtin=clear,informal" }
    }),
    --
    null_ls.builtins.formatting.prettier_d_slim, -- HTML/JS/Markdown/... formatting
    null_ls.builtins.formatting.taplo,           -- TOML
    null_ls.builtins.diagnostics.clang_check,
  },
  on_attach = on_attach
})
