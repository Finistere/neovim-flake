--
-- LSP
--

require('fidget').setup({})
require("inc_rename").setup()

local hl = require("actions-preview.highlight")
require("actions-preview").setup {
  telescope = {
    sorting_strategy = "ascending",
    layout_strategy = "vertical",
    layout_config = {
      width = 0.6,
      height = 0.5,
      prompt_position = "top",
      preview_cutoff = 20,
      preview_height = function(_, _, max_lines)
        return max_lines - 15
      end,
    },
  },
  highlight_command = {
    hl.delta(),
  },
}

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

  vim.keymap.set({ 'v', 'n' }, '<leader>ca', require("actions-preview").code_actions, bopts)
  vim.keymap.set('n', '<leader>cr', ':IncRename ', bopts)
  vim.keymap.set('n', '<leader>ce', function() vim.lsp.buf.rename() end, bopts)
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

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    local bufnr = args.buf
    if client.server_capabilities.inlayHintProvider then
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled(), { bufnr = bufnr })
    end
    format_on_save(client, bufnr)
    attach_keymaps(client, bufnr)
    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
  end
})

local capabilities = require('cmp_nvim_lsp').default_capabilities()
-- for nvim-ufo folding.
capabilities.textDocument.foldingRange = {
  dynamicRegistration = false,
  lineFoldingOnly = true
}

local lspconfig = require('lspconfig')
lspconfig.bashls.setup {}
lspconfig.nil_ls.setup {}
lspconfig.tsserver.setup {}

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
}

vim.g.rustaceanvim = {
  -- Plugin configuration
  tools = {
  },
  -- LSP configuration
  server = {
    on_attach = function(client, bufnr)
      local bopts = { noremap = true, silent = true, buffer = bufnr }
      vim.keymap.set('n', '<C-space>', 'RustLsp hover actions', bopts)
    end,
    default_settings = {
      -- rust-analyzer language server configuration
      ['rust-analyzer'] = {
        cargo = {
          allFeatures = true
        }
      },
    },
  },
  dap = {
    adapter = require('rustaceanvim.config')
        .get_codelldb_adapter(vim.g.codelldb_path, vim.g.liblldb_path),
  },
}

-- Rust pre-configured by rust-tools
-- local rt = require('rust-tools')
-- rt.setup({
--   server = {
--     on_attach = function(client, bufnr)
--       on_attach(client, bufnr)
--       local bopts = { noremap = true, silent = true, buffer = bufnr }
--       vim.keymap.set('n', '<C-space>', rt.hover_actions.hover_actions, bopts)
--       -- keymap('K', rt.hover_range.hover_range, bopts)
--     end,
--     settings = {
--       ['rust-analyzer'] = {
--         cargo = {
--           allFeatures = true
--           -- target = "wasm32-unknown-unknown"
--         }
--       }
--     }
--   },
--   tools = {
--     hover_actions = {
--       auto_focus = true,
--     },
--   },
--   -- https://github.com/simrat39/rust-tools.nvim/wiki/Debugging#codelldb-a-better-debugging-experience
-- })
require('crates').setup {
  -- null_ls = { enabled = true }
}

local null_ls = require('null-ls')
null_ls.setup({
  sources = {
    -- Nix
    null_ls.builtins.formatting.alejandra,
    null_ls.builtins.diagnostics.deadnix,
    null_ls.builtins.diagnostics.statix,
    -- Shell
    null_ls.builtins.formatting.shfmt.with({
      extra_args = { "--indent=4" }
    }),
    -- Spelling
    null_ls.builtins.diagnostics.vale,
    --
    null_ls.builtins.formatting.prettierd, -- HTML/JS/Markdown/... formatting
  },
})
