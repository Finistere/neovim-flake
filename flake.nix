{
  description = "custom neovim";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    ranger = {
      url = "github:ranger/ranger";
      flake = false;
    };
    mini-move = {
      url = "github:echasnovski/mini.move";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  } @ inputs:
    {
      # make it easy to use this flake as an overlay
      overlay = final: prev: {
        neovim = self.packages.${prev.system}.default;
      };
    }
    // flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          # enable all packages
          config = {allowUnfree = true;};
        };
        # inherit (pkgs.vscode-extensions.vadimcn) vscode-lldb;

        extraPackages = with pkgs; [
          tree-sitter
          gcc

          # Debug
          # lldb
          # vscode-lldb

          # language servers
          rnix-lsp
          rust-analyzer-unwrapped
          terraform-ls
          nodePackages.pyright
          nodePackages."typescript-language-server"
          sumneko-lua-language-server

          # null-ls
          alejandra # nix formatting
          shfmt # shell formatting
          shellcheck # shell check
          statix # code actions on nix
          deadnix # dead code
          nodePackages.prettier_d_slim # js/html/markdown/... formatting
          taplo # toml formatting
          codespell # spelling issues

          # Utilities
          ripgrep
          fd
          git
          gh # for cmp-git
          (ranger.overridePythonAttrs (old: {
            version = "1.9.4-master";
            src = inputs.ranger;
            nativeCheckInputs = with python3Packages; old.nativeCheckInputs ++ [astroid pylint];
          }))
        ];

        # installs a vim plugin from git
        plugin = with pkgs;
          repo:
            vimUtils.buildVimPluginFrom2Nix {
              pname = "${lib.strings.sanitizeDerivationName repo}";
              version = "main";
              src = builtins.getAttr repo inputs;
            };
      in
        with pkgs; rec {
          apps.default = flake-utils.lib.mkApp {
            drv = packages.default;
            exePath = "/bin/nvim";
          };

          # TODO: Need to add custom queries/markdown/injections
          # bat cache update
          packages.default = wrapNeovim neovim-unwrapped {
            viAlias = true;
            vimAlias = true;
            withPython3 = true;
            withNodeJs = false;
            withRuby = false;
            extraMakeWrapperArgs = builtins.concatStringsSep " " [
              ''--prefix PATH : "${lib.makeBinPath extraPackages}"''
            ];
            configure = {
              # import your individual vim config files here
              # you can import from files
              # or directly add the config here as a string
              customRC = builtins.concatStringsSep "\n" [
                (lib.strings.fileContents ./base.vim)
                ''
                  lua << EOF
                  ${lib.strings.fileContents ./tree-sitter.lua}
                  ${lib.strings.fileContents ./cmp.lua}
                  ${lib.strings.fileContents ./lsp.lua}
                  ${lib.strings.fileContents ./ui.lua}
                  ${lib.strings.fileContents ./editor.lua}
                  EOF
                ''
              ];
              packages.myVimPackage = {
                start = with vimPlugins; [
                  # Syntax
                  nvim-treesitter.withAllGrammars
                  # Using the maintained fork
                  nvim-ts-rainbow # matching brackets... pairs
                  nvim-treesitter-context # Show a top bar with current code context

                  # UI
                  telescope-nvim # find/search popup
                  telescope-fzf-native-nvim # Native search, for faster search
                  nvim-web-devicons # icons pack
                  nvim-tree-lua # file tree
                  gitsigns-nvim # git signs in the editor
                  bufferline-nvim # buffer manager
                  scope-nvim # associate buffers to tabs
                  lualine-nvim # bottom status line
                  vim-floaterm # floating terminal window
                  rnvimr # ranger integration, it's a bit faster to show up than vim-floaterm integration
                  (plugin "mini-move") # Moving selection with Atl+hjkl
                  marks-nvim # show marks with gutter icons
                  nvim-spectre # search and replace

                  # Nvim behavior
                  which-key-nvim
                  auto-session # reload & save automatically session for each cwd.

                  # Editor visuals
                  indent-blankline-nvim # indentation guides
                  nvim-cursorline # underlines word & highlight current line
                  nvim-colorizer-lua # show color for #000000
                  comment-nvim # toggle comment
                  range-highlight-nvim # highlight ranges (:20,+4)
                  todo-comments-nvim # highlight todo comments and list them in Trouble/Telescope
                  leap-nvim # faster navigation within a file
                  nvim-ufo # better folds

                  # Utilities
                  plenary-nvim # Utility library for lots of plugins

                  # LSP
                  nvim-lspconfig
                  # TODO: A bit buggy for completion and not that useful, need a better alternative.
                  # lsp_signature-nvim # show signature when writing arguments
                  nvim-code-action-menu # preview code actions
                  trouble-nvim # friendlier bottom window for search results
                  fidget-nvim # LSP status fidget
                  inc-rename-nvim # in-place rename preview
                  symbols-outline-nvim # lists function,class,... in separate window

                  # Null-ls
                  null-ls-nvim # LSP adapter for other plugins (formatter, linter, etc.)

                  # Rust
                  crates-nvim # Show current version of rust dependencies within Cargo.toml
                  rust-tools-nvim # advanced rust-analyzer integration

                  # Typescript
                  typescript-nvim # advanced typescript integration

                  # Completion
                  nvim-cmp
                  cmp-nvim-lsp
                  cmp-buffer
                  cmp-path
                  cmp-cmdline
                  cmp-treesitter
                  cmp-git
                  luasnip
                  cmp_luasnip
                  nvim-autopairs
                  nvim-ts-autotag
                  lspkind-nvim # VS-code pictograms for auto-completion

                  # Colorscheme
                  tokyonight-nvim
                ];
              };
            };
          };
        }
    );
}
