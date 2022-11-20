{
  description = "custom neovim";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    cmp-git = {
      url = "github:petertriho/cmp-git";
      flake = false;
    };

    leap-nvim = {
      url = "github:ggandor/leap.nvim";
      flake = false;
    };

    inc-rename-nvim = {
      url = "github:smjonas/inc-rename.nvim";
      flake = false;
    };

    neotest = {
      url = "github:nvim-neotest/neotest";
      flake = false;
    };

    neotest-rust = {
      url = "github:rouge8/neotest-rust";
      flake = false;
    };

    ranger = {
      url = "github:ranger/ranger";
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

        extraPackages = with pkgs; [
          tree-sitter
          gcc
          lldb

          # language servers
          rnix-lsp
          rust-analyzer
          terraform-ls
          nodePackages.pyright
          nodePackages."@prisma/language-server"
          sumneko-lua-language-server

          # null-ls
          alejandra # nix formatting
          shfmt # shell formatting
          shellcheck # shell check
          statix # code actions on nix
          deadnix # dead code

          # Utilities
          ripgrep
          fd
          git
          gh # for cmp-git
          (ranger.overridePythonAttrs (old: {
            version = "1.9.4-master";
            src = inputs.ranger;
            checkInputs = with python3Packages; old.checkInputs ++ [astroid pylint];
          }))

          graphviz # for rust-tools crate graph
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

          packages.default = wrapNeovim neovim-unwrapped {
            viAlias = true;
            vimAlias = true;
            withPython3 = true;
            withNodeJs = false;
            withRuby = false;
            extraMakeWrapperArgs = ''--prefix PATH : "${lib.makeBinPath extraPackages}"'';
            configure = {
              # import your individual vim config files here
              # you can import from files
              # or directly add the config here as a string
              customRC = builtins.concatStringsSep "\n" [
                (lib.strings.fileContents ./base.vim)
                ''
                  lua << EOF
                  -- Tresitter may use the another compiler in the environment otherwise.
                  require('nvim-treesitter.install').compilers = { "${gcc.out}/bin/gcc" }
                  ${lib.strings.fileContents ./tree-sitter.lua}
                  ${lib.strings.fileContents ./cmp.lua}
                  ${lib.strings.fileContents ./lsp.lua}
                  ${lib.strings.fileContents ./ui.lua}
                  ${lib.strings.fileContents ./editor.lua}
                  ${lib.strings.fileContents ./debug.lua}
                  EOF
                ''
              ];
              packages.myVimPackage = {
                start = with vimPlugins; [
                  which-key-nvim
                  (plugin "leap-nvim")

                  # Syntax
                  nvim-treesitter
                  nvim-ts-rainbow
                  nvim-treesitter-context
                  playground

                  # UI
                  telescope-nvim # find/search popup
                  telescope-fzf-native-nvim # Native search, for faster search
                  nvim-web-devicons # icons pack
                  nvim-tree-lua # file tree
                  gitsigns-nvim # git signs in the editor
                  bufferline-nvim # tab manager
                  lualine-nvim # bottom status line
                  vim-floaterm # floating terminal window
                  # rnvimr # ranger integration

                  # Editor visuals
                  indent-blankline-nvim # indentation guides
                  nvim-cursorline # underlines word & hight curent line
                  nvim-colorizer-lua # show color for #000000
                  comment-nvim # toggle comment
                  range-highlight-nvim # highlight ranges (:20,+4)
                  todo-comments-nvim # highlight todo comments and list them in Trouble/Telescope

                  # Utilities
                  plenary-nvim # Utility library for lots of plugins

                  # LSP
                  nvim-lspconfig
                  lsp_signature-nvim # show signature when writing arguments
                  nvim-code-action-menu # preview code actions
                  nvim-lightbulb # shows lightbulb for LSP actions/errors
                  trouble-nvim # friendlier bottom window for search results
                  fidget-nvim # LSP status fidget
                  (plugin "inc-rename-nvim") # in-place rename preview

                  # Null-ls
                  null-ls-nvim # LSP adapter for other plugins

                  # Rust
                  rust-tools-nvim # advanced rust-analyzer integration

                  # Debug / Test
                  (plugin "neotest")
                  (plugin "neotest-rust")
                  nvim-dap # debuger
                  nvim-dap-ui
                  nvim-dap-virtual-text

                  # Completion
                  nvim-cmp
                  cmp-nvim-lsp
                  cmp-buffer
                  cmp-path
                  cmp-cmdline
                  cmp-treesitter
                  (plugin "cmp-git")
                  luasnip
                  cmp_luasnip
                  nvim-autopairs
                  nvim-ts-autotag
                  lspkind-nvim # VS-code pictograms for auto-completion

                  # Rust
                  crates-nvim

                  # Colorscheme
                  tokyonight-nvim
                  papercolor-theme
                ];
              };
            };
          };
        }
    );
}
