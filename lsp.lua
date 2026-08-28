--
-- LSP
--

local minimal_profile = vim.g.minimal_profile == true

if not minimal_profile then
  require('fidget').setup({
    notification = {
      window = {
        avoid = { "NvimTree" }
      }
    }
  })
  require('inc_rename').setup()

  local hl = require('actions-preview.highlight')
  require('actions-preview').setup {
    backend = { 'nui' },
    nui = {
      layout = {
        size = {
          width = '60%',
          height = '50%',
        },
      },
    },
    highlight_command = {
      hl.delta(),
    },
  }
end

local augroup = vim.api.nvim_create_augroup('LspFormatting', {})

local function apply_code_action(client, kind, bufnr, timeout_ms)
  local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
  params.context = { only = { kind }, diagnostics = {} }

  local response = client:request_sync('textDocument/codeAction', params, timeout_ms, bufnr)
  if not response or not response.result then return end

  for _, action in ipairs(response.result) do
    if action.edit then
      vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
    end
    if action.command then
      client:exec_cmd(action.command, { bufnr = bufnr })
    end
  end
end

local function preferred_formatter(client, bufnr)
  local null_ls_clients = vim.lsp.get_clients({
    bufnr = bufnr,
    method = 'textDocument/formatting',
    name = 'null-ls',
  })
  return #null_ls_clients == 0 or client.name == 'null-ls'
end

local function format_on_save(bufnr)
  vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
  vim.api.nvim_create_autocmd('BufWritePre', {
    group = augroup,
    buffer = bufnr,
    callback = function()
      local zls = vim.lsp.get_clients({ bufnr = bufnr, name = 'zls' })[1]
      if zls then
        apply_code_action(zls, 'source.organizeImports', bufnr, 1000)
        apply_code_action(zls, 'source.fixAll', bufnr, 1000)
      end
      vim.lsp.buf.format({
        bufnr = bufnr,
        async = false,
        filter = function(client) return preferred_formatter(client, bufnr) end,
      })
    end,
  })
end

local function attach_keymaps(client, bufnr)
  local bopts = { noremap = true, silent = true, buffer = bufnr }

  if not minimal_profile then
    vim.keymap.set({ 'v', 'n' }, '<leader>ca', require('actions-preview').code_actions, bopts)
    vim.keymap.set('n', '<leader>cr', ':IncRename ', bopts)
  else
    vim.keymap.set({ 'v', 'n' }, '<leader>ca', function() vim.lsp.buf.code_action() end, bopts)
    vim.keymap.set('n', '<leader>cr', function() vim.lsp.buf.rename() end, bopts)
  end

  vim.keymap.set('n', '<leader>ce', function() vim.lsp.buf.rename() end, bopts)
  -- Format file
  -- vim.keymap.set('n', '<leader>cf', function() vim.lsp.buf.format({ bufnr = bufnr }) end, bopts)
  vim.keymap.set(
    'n',
    '<leader>cf',
    function() vim.lsp.buf.code_action({ apply = true, context = { only = { 'quickfix' } } }) end,
    bopts
  )
  vim.keymap.set('n', 'gd', '<cmd>FzfLua lsp_definitions<cr>', bopts)
  vim.keymap.set('n', 'gt', '<cmd>FzfLua lsp_typedefs<cr>', bopts)
  vim.keymap.set('n', 'gi', '<cmd>FzfLua lsp_implementations<cr>', bopts)
  vim.keymap.set('n', 'gr', '<cmd>FzfLua lsp_references<cr>', bopts)
  vim.keymap.set('n', 'gc', '<cmd>FzfLua lsp_incoming_calls<cr>', bopts)
  vim.keymap.set('n', 'go', '<cmd>FzfLua lsp_outgoing_calls<cr>', bopts)
  vim.keymap.set('', 'K', vim.lsp.buf.hover, bopts)
end

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    local bufnr = args.buf
    if client.server_capabilities.inlayHintProvider then
      vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
    end
    format_on_save(bufnr)
    attach_keymaps(client, bufnr)
    vim.bo[bufnr].omnifunc = 'v:lua.vim.lsp.omnifunc'
  end
})

local capabilities = require('blink.cmp').get_lsp_capabilities({
  -- for nvim-ufo folding.
  textDocument = {
    foldingRange = {
      dynamicRegistration = false,
      lineFoldingOnly = true,
    },
  },
})

vim.lsp.config('*', {
  capabilities = capabilities,
})

-- Allow projects to override ZLS
local zls_cmd = os.getenv('ZLS_CMD')
vim.lsp.config('zls', {
  cmd = zls_cmd and { zls_cmd } or nil,
})
vim.lsp.enable('zls')

if not minimal_profile then
  local null_ls = require('null-ls')
  null_ls.setup({
    sources = {
      null_ls.builtins.formatting.shfmt.with({
        extra_args = { '--indent=4' },
      }),
      -- Nix
      null_ls.builtins.formatting.alejandra,
      null_ls.builtins.diagnostics.deadnix,
      null_ls.builtins.diagnostics.statix,
      -- Spelling
      -- null_ls.builtins.diagnostics.vale,
      --
      null_ls.builtins.formatting.prettierd, -- HTML/JS/Markdown/... formatting
    },
  })

  vim.lsp.config('clangd', {
    cmd = { 'clangd', '--background-index', '--compile-commands-dir=.' },
  })

  vim.lsp.enable({
    'basedpyright',
    'bashls',
    'clangd',
    'graphql',
    'nil_ls',
    'taplo',
    'ts_ls',
  })

  vim.g.rustaceanvim = {
    -- Plugin configuration
    tools = {
    },
    -- LSP configuration
    server = {
      capabilities = capabilities,
      on_attach = function(client, bufnr)
        local bopts = { noremap = true, silent = true, buffer = bufnr }
        vim.keymap.set('n', '<C-space>', 'RustLsp hover actions', bopts)
      end,
      default_settings = {
        -- rust-analyzer language server configuration
        -- ['rust-analyzer'] = {
        --   cargo = {
        --     allFeatures = true
        --   }
        -- },
      },
    },
  }

  require('crates').setup({
    lsp = {
      enabled = true,
      completion = true,
    },
  })
end
