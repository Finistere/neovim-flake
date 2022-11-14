--
-- Treesitter
--

-- uses nix store path instead.
local parser_install_dir = '~/.local/share/nvim/site/parser'
require('nvim-treesitter.configs').setup {
  ensure_installed = {
    'rust', 'bash', 'nix', 'json', 'typescript', 'javascript', 'python', 'toml',
  },
  auto_install = true,
  highlight = {
    enable = true,
  },
  parser_install_dir = parser_install_dir,
  indent = { enable = true },
  rainbow = {
    enable = true,
    extended_mode = true,
    max_file_lines = 2000,
  },
}
vim.opt.runtimepath:append(parser_install_dir)

require('treesitter-context').setup {
  enable = true,
}
