--
-- Treesitter
--

require('nvim-treesitter.configs').setup {
  -- All grammars are installed through Nix
  ensure_installed = {},
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
  query_linter = {
    enable = true,
    use_virtual_text = true,
    lint_events = { "BufWrite", "CursorHold" }
  }
}

require('treesitter-context').setup {
  enable = true,
}
