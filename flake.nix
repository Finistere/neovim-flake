{
  description = "custom neovim";

  inputs = {
    # use latest rust-analyzer
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    ranger = {
      url = "github:ranger/ranger";
      flake = false;
    };
    mini-move = {
      url = "github:echasnovski/mini.move";
      flake = false;
    };
    nvim-rainbow-delimiter = {
      url = "git+https://gitlab.com/HiPhish/rainbow-delimiters.nvim.git";
      flake = false;
    };
    rustaceanvim = {
      url = "github:mrcjkb/rustaceanvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fidget-nvim = {
      url = "github:j-hui/fidget.nvim";
      flake = false;
    };
    tokyonight-nvim = {
      url = "github:folke/tokyonight.nvim";
      flake = false;
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
          # enable all packages
          config = {
            allowUnfree = true;
          };
          overlays = [
            (final: prev: {
              # does nothing...
              # rust-analyzer-unwrapped = prev.rust-analyzer-unwrapped.overrideAttrs (old: rec {
              #   version = "2024-08-01";
              #   src = prev.fetchFromGitHub {
              #     owner = "rust-lang";
              #     repo = "rust-analyzer";
              #     rev = version;
              #     hash = "sha256-mUVnhgiQNnvn/lyMfh1d2XqiUE/3rwF993uUrcq3pS0=";
              #   };
              #   cargoDeps = old.cargoDeps.overrideAttrs {
              #     inherit src;
              #     outputHash = "sha256-0PKoZhypSZk6vAaho8naMDRYc58AiQbJ1DW48owsMUQ=";
              #   };
              # });
              # neovim-unwrapped = prev.neovim-unwrapped.overrideAttrs (old: {
              #   version = "nightly";
              #   src = prev.fetchFromGitHub {
              #     owner = "neovim";
              #     repo = "neovim";
              #     rev = "nightly";
              #     hash = "sha256-Hw/alNyPST9zK8j/1//Z2waDn65SBkNWtr0waN5HmU8=";
              #   };
              # });
            })
          ];
        };

        extraPackages = with pkgs; [
          tree-sitter
          gcc

          # for copilot
          nodejs

          # language servers
          nil
          (rust-analyzer-unwrapped.override {
            useMimalloc = true;
          })
          terraform-ls
          pyright
          nodePackages.typescript-language-server
          bash-language-server
          lua-language-server
          nodePackages.graphql-language-service-cli
          # llm-ls

          # none-ls
          alejandra # nix formatting
          shfmt # shell formatting
          shellcheck # shell check
          statix # code actions on nix
          deadnix # dead code
          prettierd # js/html/markdown/... formatting
          taplo # toml formatting

          # Utilities
          ripgrep
          fd
          git
          gh # for cmp-git
          delta
          (ranger.overridePythonAttrs (old: {
            version = "1.9.4-master";
            src = inputs.ranger;
            nativeCheckInputs = with python3Packages;
              old.nativeCheckInputs
              ++ [
                astroid
                pylint
              ];
          }))
        ];

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

          extraMakeWrapperArgs = ''--prefix PATH : "${lib.makeBinPath extraPackages}"'';
          extraMakeWrapperLuaCArgs = ''--suffix LUA_CPATH ";" "${
              lib.concatMapStringsSep ";" luaPackages.getLuaCPath resolvedExtraLuaPackages
            }"'';
          extraMakeWrapperLuaArgs = ''--suffix LUA_PATH ";" "${
              lib.concatMapStringsSep ";" luaPackages.getLuaPath resolvedExtraLuaPackages
            }"'';
        in rec {
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
            extraMakeWrapperArgs = builtins.concatStringsSep " " [
              extraMakeWrapperArgs
              extraMakeWrapperLuaCArgs
              extraMakeWrapperLuaArgs
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
                  ${lib.strings.fileContents ./llm.lua}
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
                  ((plugin "nvim-rainbow-delimiter").overrideAttrs {
                    nvimSkipModules = [
                      "rainbow-delimiters._test.highlight"
                      "rainbow-delimiters.types"
                    ];
                  }) # matching brackets... pairs
                  nvim-treesitter-context # Show a top bar with current code context
                  nvim-osc52 # copy paste directly into system clipboard through ssh
                  (plugin "tree-sitter-language-injection-nvim")

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
                  (plugin "mini-move") # Moving selection with Atl+hjkl
                  marks-nvim # show marks with gutter icons
                  diffview-nvim # git diffs

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

                  # LSP
                  nvim-lspconfig
                  # TODO: A bit buggy for completion and not that useful, need a better alternative.
                  # lsp_signature-nvim # show signature when writing arguments
                  actions-preview-nvim # preview code actions
                  trouble-nvim # friendlier bottom window for search results
                  (plugin "fidget-nvim") # LSP status fidget
                  inc-rename-nvim # in-place rename preview

                  # LLM
                  copilot-cmp # cmp integration
                  copilot-lua # copilot

                  # Null-ls
                  none-ls-nvim # LSP adapter for other plugins (formatter, linter, etc.)

                  # Rust
                  ((plugin "crates-nvim").overrideAttrs {
                    nvimSkipModules = ["crates.null-ls"];
                  }) # Show current version of rust dependencies within Cargo.toml
                  ((plugin "rustaceanvim").overrideAttrs {
                    nvimSkipModules = ["rustaceanvim.neotest.init"];
                  }) # Rust integration

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
                  ((plugin "tokyonight-nvim").overrideAttrs {
                    nvimSkipModules = [
                      "tokyonight.extra.fzf"
                      "tokyonight.docs"
                    ];
                  })

                  # Debug
                  nvim-dap
                  nvim-dap-ui
                  nvim-dap-virtual-text
                ];
              };
            };
          };
        }
    );
}
