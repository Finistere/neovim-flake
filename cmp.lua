--
-- Auto-completion
--

require('nvim-ts-autotag').setup()
require('nvim-autopairs').setup()

vim.o.completeopt = 'menu,menuone,noselect'
vim.o.pumheight = 15 -- max items suggested

require('blink.cmp').setup({
  keymap = {
    preset = 'none',
    ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
    ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
    ['<C-Space>'] = { 'show', 'show_documentation', 'hide_documentation' },
    ['<C-e>'] = { 'hide', 'fallback' },
    ['<CR>'] = { 'accept', 'fallback' },
    ['<Tab>'] = { 'select_next', 'snippet_forward', 'fallback' },
    ['<S-Tab>'] = { 'select_prev', 'snippet_backward', 'fallback' },
  },
  completion = {
    list = {
      selection = {
        preselect = false,
        auto_insert = false,
      },
    },
    menu = {
      max_height = 15,
      draw = {
        components = {
          label = {
            width = { max = 50 },
          },
        },
      },
    },
    documentation = {
      auto_show = false,
    },
  },
  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer', 'git' },
    providers = {
      git = {
        module = 'blink-cmp-git',
        name = 'Git',
        enabled = function()
          return vim.bo.filetype == 'gitcommit'
        end,
        opts = {},
      },
    },
  },
  cmdline = {
    sources = function()
      local cmd_type = vim.fn.getcmdtype()
      if cmd_type == '/' or cmd_type == '?' then return { 'buffer' } end
      if cmd_type == ':' then return { 'cmdline', 'path' } end
      return {}
    end,
    completion = {
      menu = {
        auto_show = true,
      },
    },
  },
  fuzzy = {
    implementation = 'prefer_rust',
    prebuilt_binaries = {
      download = false,
    },
  },
})
