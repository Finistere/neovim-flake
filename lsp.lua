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

-- Servers may return whole-file or unchanged edits; only write changed lines to the real buffer.
local function apply_local_text_edits(batches, bufnr, encoding, annotations)
  local old_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local scratch = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(scratch, 0, -1, false, old_lines)
  for _, edits in ipairs(batches) do
    vim.lsp.util.apply_text_edits(edits, scratch, encoding, annotations)
  end
  local new_lines = vim.api.nvim_buf_get_lines(scratch, 0, -1, false)
  vim.api.nvim_buf_delete(scratch, { force = true })

  local first = 1
  while first <= #old_lines and first <= #new_lines and old_lines[first] == new_lines[first] do
    first = first + 1
  end
  if first > #old_lines and first > #new_lines then return end

  local old_last = #old_lines
  local new_last = #new_lines
  while old_last >= first and new_last >= first and old_lines[old_last] == new_lines[new_last] do
    old_last = old_last - 1
    new_last = new_last - 1
  end

  local replacement = {}
  for i = first, new_last do
    table.insert(replacement, new_lines[i])
  end
  vim.api.nvim_buf_set_lines(bufnr, first - 1, old_last, false, replacement)
end

local function apply_code_action_edit(edit, bufnr, encoding)
  local uri = vim.uri_from_bufnr(bufnr)
  local batches = {}

  if edit.documentChanges then
    for _, change in ipairs(edit.documentChanges) do
      if change.kind or change.textDocument.uri ~= uri then
        vim.lsp.util.apply_workspace_edit(edit, encoding)
        return
      end
      table.insert(batches, change.edits)
    end
  elseif edit.changes then
    for changed_uri, edits in pairs(edit.changes) do
      if changed_uri ~= uri then
        vim.lsp.util.apply_workspace_edit(edit, encoding)
        return
      end
      table.insert(batches, edits)
    end
  end

  if #batches > 0 then
    apply_local_text_edits(batches, bufnr, encoding, edit.changeAnnotations)
  end
end

local function apply_code_action(client, kind, bufnr, timeout_ms)
  local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
  params.context = { only = { kind }, diagnostics = {} }

  local response = client:request_sync('textDocument/codeAction', params, timeout_ms, bufnr)
  if not response or not response.result then return end

  for _, action in ipairs(response.result) do
    if action.edit then
      apply_code_action_edit(action.edit, bufnr, client.offset_encoding)
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

local function format_buffer(bufnr)
  local clients = vim.lsp.get_clients({ bufnr = bufnr, method = 'textDocument/formatting' })
  for _, client in pairs(clients) do
    if preferred_formatter(client, bufnr) then
      local params = vim.lsp.util.make_formatting_params()
      local response, err = client:request_sync('textDocument/formatting', params, 1000, bufnr)
      if response and response.result then
        apply_local_text_edits({ response.result }, bufnr, client.offset_encoding)
      elseif err then
        vim.notify(string.format('[LSP][%s] %s', client.name, err), vim.log.levels.WARN)
      end
    end
  end
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
      format_buffer(bufnr)
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
  -- Keep this definition self-contained: nvim-lspconfig, which normally
  -- supplies these defaults, is intentionally not part of the minimal profile.
  cmd = { zls_cmd or 'zls' },
  filetypes = { 'zig', 'zir' },
  root_markers = { 'zls.json', 'build.zig', '.git' },
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
      null_ls.builtins.formatting.clang_format.with({
        command = os.getenv('CLANG_FORMAT') or 'clang-format',
      }),
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
