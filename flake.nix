{
  description = "custom neovim";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
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

          # Utilities
          ripgrep
          fd
          git
          gh # for cmp-git

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
            withPython3 = false;
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
                  ${lib.strings.fileContents ./tree-sitter.lua}
                  ${lib.strings.fileContents ./cmp.lua}
                  ${lib.strings.fileContents ./lsp.lua}
                  ${lib.strings.fileContents ./visual.lua}
                  EOF
                ''
              ];
              packages.myVimPackage = {
                start = with vimPlugins; [
                  which-key-nvim
                  (plugin "leap-nvim")

                  # Syntax
                  (nvim-treesitter.withPlugins (plugins: pkgs.tree-sitter.allGrammars))
                  nvim-ts-rainbow
                  nvim-treesitter-context
                  playground

                  # UI
                  telescope-nvim
                  nvim-web-devicons
                  nvim-tree-lua
                  gitsigns-nvim
                  bufferline-nvim
                  lualine-nvim

                  # Editor visuals
                  indent-blankline-nvim
                  nvim-cursorline

                  # Utilities
                  plenary-nvim

                  # LSP
                  nvim-lspconfig
                  lsp_signature-nvim
                  lspsaga-nvim
                  nvim-code-action-menu
                  nvim-lightbulb
                  trouble-nvim
                  lspkind-nvim
                  fidget-nvim
                  (plugin "inc-rename-nvim")

                  # Null-ls
                  null-ls-nvim

                  # Rust
                  rust-tools-nvim

                  # Debug
                  (plugin "neotest")
                  (plugin "neotest-rust")
                  nvim-dap
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

                  # Rust
                  crates-nvim

                  # Colorscheme
                  tokyonight-nvim
                ];
              };
            };
          };
        }
    );
}
