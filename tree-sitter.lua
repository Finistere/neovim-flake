--
-- Treesitter
--

-- If not specified, it uses a nix store path instead which is read-only.
local parser_install_dir = '~/.local/share/nvim/site/parser'
require('nvim-treesitter.configs').setup {
  -- not really necessary
  ensure_installed = {
    'rust', 'bash', 'nix', 'json', 'typescript', 'javascript', 'python', 'toml',
  },
  -- install a language if missing. Both this and previous option should be deactivated if
  -- languages are installed through Nix which currently doesn't work properly.
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
