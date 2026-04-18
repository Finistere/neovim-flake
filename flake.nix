{
  description = "custom neovim";

  inputs = {
    # use latest rust-analyzer
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nvim-rainbow-delimiter = {
      url = "git+https://gitlab.com/HiPhish/rainbow-delimiters.nvim.git";
      flake = false;
    };
    rustaceanvim = {
      url = "github:mrcjkb/rustaceanvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    crates-nvim = {
      url = "github:saecki/crates.nvim";
      flake = false;
    };
    tree-sitter-language-injection-nvim = {
      url = "github:DariusCorvus/tree-sitter-language-injection.nvim";
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
          config = {
            allowUnfree = true;
          };
        };

        minimalExtraPackages = with pkgs; [
          tree-sitter
          gcc

          # none-ls
          shfmt # shell formatting

          # Utilities
          ripgrep
          fd
          git
          gh # for cmp-git
          delta
          ranger
        ];

        fullExtraPackages =
          minimalExtraPackages
          ++ (with pkgs; [
            # for copilot
            nodejs

            # language servers
            nil
            (rust-analyzer-unwrapped.override {
              useMimalloc = true;
            })
            terraform-ls
            typescript-language-server
            bash-language-server
            lua-language-server
            graphql-language-service-cli
            zls # Zig
            basedpyright # Python

            # none-ls
            alejandra # nix formatting
            statix # code actions on nix
            deadnix # dead code
            prettierd # js/html/markdown/... formatting
            taplo # toml formatting
            llvmPackages_20.clang-tools
          ]);

        luaPackages = pkgs.lua.pkgs;
        resolvedExtraLuaPackages = with luaPackages; [];
      in
        with pkgs; let
          # installs a vim plugin from git
          plugin = repo:
            vimUtils.buildVimPlugin {
              pname = "${lib.strings.sanitizeDerivationName repo}";
              version = "main";
              src = builtins.getAttr repo inputs;
            };

          extraMakeWrapperLuaCArgs = ''--suffix LUA_CPATH ";" "${
              lib.concatMapStringsSep ";" luaPackages.getLuaCPath resolvedExtraLuaPackages
            }"'';
          extraMakeWrapperLuaArgs = ''--suffix LUA_PATH ";" "${
              lib.concatMapStringsSep ";" luaPackages.getLuaPath resolvedExtraLuaPackages
            }"'';
          tsGrammarNames = lib.attrNames pkgs.vimPlugins.nvim-treesitter.grammarPlugins;
          tsGrammarNamesLua = lib.generators.toLua {} tsGrammarNames;
          minimalPlugins = with vimPlugins; [
            # Syntax
            nvim-treesitter.withAllGrammars
            # Using the maintained fork
            ((plugin "nvim-rainbow-delimiter").overrideAttrs {
              nvimSkipModules = [
                "rainbow-delimiters._test.highlight"
                "rainbow-delimiters.types"
              ];
            }) # matching brackets... pairs
            nvim-treesitter-context # Show a top bar with current code context
            nvim-osc52 # copy paste directly into system clipboard through ssh

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
            marks-nvim # show marks with gutter icons
            diffview-nvim # git diffs
            trouble-nvim # friendlier bottom window for search results

            # Nvim behavior
            which-key-nvim
            auto-session # reload & save automatically session for each cwd.

            # Editor visuals
            indent-blankline-nvim # indentation guides
            nvim-cursorline # underlines word & highlight current line
            comment-nvim # toggle comment
            range-highlight-nvim # highlight ranges (:20,+4)
            todo-comments-nvim # highlight todo comments and list them in Trouble/Telescope
            leap-nvim # faster navigation within a file
            nvim-ufo # better folds
            nvim-surround # surround text objects

            # Utilities
            plenary-nvim # Utility library for lots of plugins
            render-markdown-nvim

            # Rust
            ((plugin "crates-nvim").overrideAttrs {
              nvimSkipModules = ["crates.null-ls"];
            }) # Show current version of rust dependencies within Cargo.toml

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

            # LSP
            nvim-lspconfig
            none-ls-nvim # LSP adapter for other plugins (formatter, linter, etc.)
          ];
          fullPlugins =
            minimalPlugins
            ++ (with vimPlugins; [
              # LSP
              actions-preview-nvim # preview code actions
              fidget-nvim # LSP status fidget
              inc-rename-nvim # in-place rename preview

              # Today always require a `.config/nvim/after` to exist which is annoying.
              (plugin "tree-sitter-language-injection-nvim")

              # Rust
              ((plugin "rustaceanvim").overrideAttrs {
                nvimSkipModules = ["rustaceanvim.neotest.init"];
              }) # Rust integration

              # LLM
              copilot-cmp # cmp integration
              copilot-lua # copilot

              # Debug
              nvim-dap
              nvim-dap-ui
              nvim-dap-virtual-text
            ]);
          mkCustomRC = minimal:
            builtins.concatStringsSep "\n" [
              (lib.strings.fileContents ./base.vim)
              ''
                lua << EOF
                vim.g.minimal_profile = ${
                  if minimal
                  then "true"
                  else "false"
                }
                vim.g.treesitter_grammars = ${tsGrammarNamesLua}
                ${lib.strings.fileContents ./tree-sitter.lua}
                ${lib.strings.fileContents ./cmp.lua}
                ${lib.strings.fileContents ./lsp.lua}
                ${
                  if minimal
                  then ""
                  else lib.strings.fileContents ./llm.lua
                }
                ${lib.strings.fileContents ./ui.lua}
                ${lib.strings.fileContents ./editor.lua}
                EOF
              ''
            ];
          mkPackage = {minimal ? false}:
            wrapNeovim neovim-unwrapped {
              viAlias = true;
              vimAlias = true;
              withPython3 = true;
              withNodeJs = false;
              withRuby = false;
              extraMakeWrapperArgs = builtins.concatStringsSep " " [
                (
                  let
                    extraPackages =
                      if minimal
                      then minimalExtraPackages
                      else fullExtraPackages;
                  in ''--prefix PATH : "${lib.makeBinPath extraPackages}"''
                )
                extraMakeWrapperLuaCArgs
                extraMakeWrapperLuaArgs
              ];
              configure = {
                customRC = mkCustomRC minimal;
                packages.myVimPackage = {
                  start =
                    if minimal
                    then minimalPlugins
                    else fullPlugins;
                };
              };
            };
        in rec {
          apps.default = flake-utils.lib.mkApp {
            drv = packages.default;
            exePath = "/bin/nvim";
          };

          apps.minimal = flake-utils.lib.mkApp {
            drv = packages.minimal;
            exePath = "/bin/nvim";
          };

          packages.default = mkPackage {};
          packages.minimal = mkPackage {minimal = true;};
        }
    );
}
