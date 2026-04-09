--
-- LSP
--

require('fidget').setup({
  notification = {
    window = {
      avoid = {"NvimTree"}
    }
  }
})
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

local function apply_code_action(kind, bufnr, timeout_ms)
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  local encoding = nil
  for _, client in ipairs(clients) do
    if client.name == "zls" then
      encoding = client.offset_encoding
      break
    end
  end
  if not encoding and clients[1] and clients[1].offset_encoding then
    encoding = clients[1].offset_encoding
  end
  encoding = encoding or "utf-16"

  local params = vim.lsp.util.make_range_params(0, encoding)
  params.context = { only = { kind }, diagnostics = {} }

  local results = vim.lsp.buf_request_sync(bufnr, "textDocument/codeAction", params, timeout_ms)
  if not results then return end

  -- Collect all text edits for this buffer from the code action results.
  local all_edits = {}
  for _, res in pairs(results) do
    for _, action in ipairs(res.result or {}) do
      if action.edit then
        local changes = action.edit.changes or {}
        local doc_changes = action.edit.documentChanges or {}

        for _, change in ipairs(doc_changes) do
          if change.edits then
            for _, edit in ipairs(change.edits) do
              table.insert(all_edits, edit)
            end
          end
        end

        local uri = vim.uri_from_bufnr(bufnr)
        if changes[uri] then
          for _, edit in ipairs(changes[uri]) do
            table.insert(all_edits, edit)
          end
        end
      end
      if action.command then
        vim.lsp.buf.execute_command(action.command)
      end
    end
  end

  if #all_edits == 0 then return end

  -- Apply edits on a scratch buffer to compute the final result without
  -- polluting the real buffer's undo history.
  local old_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local scratch = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(scratch, 0, -1, false, old_lines)
  vim.lsp.util.apply_text_edits(all_edits, scratch, encoding)
  local new_lines = vim.api.nvim_buf_get_lines(scratch, 0, -1, false)
  vim.api.nvim_buf_delete(scratch, { force = true })

  -- Find the minimal range of changed lines so we don't replace the
  -- entire buffer (which would reset the cursor position).
  local first = 1
  local old_len = #old_lines
  local new_len = #new_lines
  while first <= old_len and first <= new_len and old_lines[first] == new_lines[first] do
    first = first + 1
  end
  if first > old_len and first > new_len then return end -- no change

  local old_last = old_len
  local new_last = new_len
  while old_last >= first and new_last >= first and old_lines[old_last] == new_lines[new_last] do
    old_last = old_last - 1
    new_last = new_last - 1
  end

  local replacement = {}
  for i = first, new_last do
    table.insert(replacement, new_lines[i])
  end

  -- Apply the diff as a single undo entry (0-based indexing for the API)
  vim.api.nvim_buf_set_lines(bufnr, first - 1, old_last, false, replacement)
end

local function zls_fixups_on_save(bufnr)
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = augroup,
    buffer = bufnr,
    callback = function()
      apply_code_action("source.organizeImports", bufnr, 1000)
      apply_code_action("source.fixAll", bufnr, 1000)
      vim.lsp.buf.format({ bufnr = bufnr, async = false })
    end,
  })
end

local function format_on_save(client, bufnr)
  if client.name == "zls" then
    zls_fixups_on_save(bufnr)
  elseif client:supports_method("textDocument/formatting") then
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

vim.lsp.enable('taplo')
vim.lsp.enable('graphql')
vim.lsp.enable('bashls')
vim.lsp.enable('nil_ls')
vim.lsp.enable('ts_ls')

-- https://zigtools.org/zls/editors/vim/nvim/
vim.lsp.config['zls'] = {
  -- Set to 'zls' if `zls` is in your PATH
  cmd = { 'zls' },
  filetypes = { 'zig' },
  root_markers = { 'build.zig' },
  -- There are two ways to set config options:
  --   - edit your `zls.json` that applies to any editor that uses ZLS
  --   - set in-editor config options with the `settings` field below.
  --
  -- Further information on how to configure ZLS:
  -- https://zigtools.org/zls/configure/
  settings = {
    -- zls = {
    --   -- Whether to enable build-on-save diagnostics
    --   --
    --   -- Further information about build-on save:
    --   -- https://zigtools.org/zls/guides/build-on-save/
    --   -- enable_build_on_save = true,
    --
    --   -- omit the following line if `zig` is in your PATH
    --   -- zig_exe_path = '/path/to/zig_executable'
    -- }
  },
}
vim.lsp.enable('zls')

-- Allow projects to override ZLS
local zls_cmd = os.getenv("ZLS_CMD")
vim.lsp.config('zls', {
  cmd = zls_cmd and {zls_cmd} or nil,
})

-- https://github.com/LuaLS/lua-language-server/issues/783
-- local runtime_path = vim.split(package.path, ';')
-- table.insert(runtime_path, 'lua/?.lua')
-- table.insert(runtime_path, 'lua/?/init.lua')
-- lspconfig.lua_ls.setup {
--   capabilities = capabilities,
--   settings = {
--     Lua = {
--       runtime = {
--         -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
--         version = 'LuaJIT',
--         -- Setup your lua path
--         path = runtime_path,
--       },
--       diagnostics = {
--         -- Get the language server to recognize the `vim` global
--         globals = { 'vim' },
--       },
--       workspace = {
--         -- Make the server aware of Neovim runtime files
--         library = vim.api.nvim_get_runtime_file('', true),
--         checkThirdParty = false,
--       },
--     }
--   },
-- }

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
  -- dap = {
  --   adapter = require('rustaceanvim.config')
  --       .get_codelldb_adapter(vim.g.codelldb_path, vim.g.liblldb_path),
  -- },
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

vim.lsp.enable('basedpyright')

vim.lsp.enable("clangd")
vim.lsp.config("clangd", {
  cmd = { "clangd", "--background-index", "--compile-commands-dir=." },
})

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
    -- null_ls.builtins.diagnostics.vale,
    --
    null_ls.builtins.formatting.prettierd, -- HTML/JS/Markdown/... formatting
  },
})
