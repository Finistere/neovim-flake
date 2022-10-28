--
-- Treesitter
--

require('nvim-treesitter.configs').setup {
  auto_install = false,
  highlight = {
    enable = true,
  },
  indent = { enable = true },
  rainbow = {
    enable = true,
    extended_mode = true,
    max_file_lines = 2000,
  },
}

require('treesitter-context').setup {
  enable = true,
}

-- format on save
vim.cmd([[
  autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync()
]])

