{
  description = "custom neovim";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";

    cmp-git = {
      url = "github:petertriho/cmp-git";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    {
      # make it easy to use this flake as an overlay
      overlay = final: prev: {
        neovim = self.packages.${prev.system}.default;
      };
    } //
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          # enable all packages
          config = { allowUnfree = true; };
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

          # Utilities
          ripgrep
          fd
          fzf
          git
          gh # for cmp-git
          curl
        ];

        # installs a vim plugin from git
        plugin = with pkgs; repo: vimUtils.buildVimPluginFrom2Nix {
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
          withNodeJs = true;
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
                ${lib.strings.fileContents ./syntax.lua}
                ${lib.strings.fileContents ./cmp.lua}
                ${lib.strings.fileContents ./lsp.lua}
                ${lib.strings.fileContents ./visual.lua}
                EOF
              ''
            ];
            packages.myVimPackage = {
              start = with vimPlugins; [
                which-key-nvim

                # Syntax
                (nvim-treesitter.withPlugins (_: tree-sitter.allGrammars))
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
