{
  description = "custom neovim";

  inputs = {
    # use latest rust-analyzer
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nvim-rainbow-delimiter = {
      url = "git+https://gitlab.com/HiPhish/rainbow-delimiters.nvim.git";
      flake = false;
    };
    tree-sitter-language-injection-nvim = {
      url = "github:DariusCorvus/tree-sitter-language-injection.nvim";
      flake = false;
    };
    diffchar-nvim = {
      url = "github:rickhowe/diffchar.vim";
      flake = false;
    };
    fidget-nvim = {
      url = "github:j-hui/fidget.nvim";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    supportedSystems = [
      "aarch64-darwin"
      "aarch64-linux"
      "x86_64-linux"
    ];
    packagesFor = system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfreePredicate = pkg:
          builtins.elem (nixpkgs.lib.getName pkg) [
            "cmd-parser.nvim"
            "scope.nvim"
          ];
      };

      lfPreview = pkgs.writeShellScript "lf-preview" ''
        exec ${pkgs.lib.getExe pkgs.bat} \
          --color=always \
          --style=numbers \
          --paging=never \
          --terminal-width "$2" \
          --line-range ":$3" \
          -- "$1"
      '';
      lfWithPreview = pkgs.writeShellScriptBin "lf" ''
        exec ${pkgs.lib.getExe pkgs.lf} \
          -command ${pkgs.lib.escapeShellArg "set previewer ${lfPreview}"} \
          "$@"
      '';

      minimalExtraPackages = with pkgs; [
        # Utilities
        ripgrep
        fd
        gitMinimal
        gh # for blink-cmp-git
        delta
        lfWithPreview
        zls # Zig
      ];

      fullExtraPackages =
        minimalExtraPackages
        ++ (with pkgs; [
          # language servers
          nil
          (rust-analyzer-unwrapped.override {
            useMimalloc = true;
          })
          typescript-language-server
          bash-language-server
          graphql-language-service-cli
          basedpyright # Python

          # none-ls
          shfmt # shell formatting
          alejandra # nix formatting
          statix # code actions on nix
          deadnix # dead code
          prettierd # js/html/markdown/... formatting
          taplo # toml formatting
          clang-tools
        ]);
    in
      with pkgs; let
        # installs a vim plugin from git
        plugin = repo:
          vimUtils.buildVimPlugin {
            pname = "${lib.strings.sanitizeDerivationName repo}";
            version = "main";
            src = builtins.getAttr repo inputs;
          };

        tsGrammarNames = [
          "asm"
          "bash"
          "c"
          "cmake"
          "comment"
          "cpp"
          "css"
          "cuda"
          "diff"
          "dockerfile"
          "fish"
          "git_config"
          "git_rebase"
          "gitattributes"
          "gitcommit"
          "gitignore"
          "go"
          "graphql"
          "hcl"
          "html"
          "javascript"
          "jjdescription"
          "json"
          "lua"
          "make"
          "markdown"
          "markdown_inline"
          "nix"
          "python"
          "query"
          "regex"
          "requirements"
          "rust"
          "sql"
          "terraform"
          "toml"
          "tsx"
          "typescript"
          "vim"
          "vimdoc"
          "yaml"
          "zig"
        ];
        treesitterWithGrammars = vimPlugins.nvim-treesitter.withPlugins (
          grammars: map (name: grammars.${name}) tsGrammarNames
        );
        commonPlugins = with vimPlugins; [
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
          fzf-lua # find/search popup
          nvim-web-devicons # icons pack
          nvim-tree-lua # file tree
          gitsigns-nvim # git signs in the editor
          bufferline-nvim # buffer manager
          scope-nvim # associate buffers to tabs
          lualine-nvim # bottom status line
          vim-floaterm # floating terminal window
          marks-nvim # show marks with gutter icons
          diffview-plus-nvim # git diffs
          (plugin "diffchar-nvim")
          trouble-nvim # friendlier bottom window for search results

          # Nvim behavior
          which-key-nvim
          auto-session # reload & save automatically session for each cwd.

          # Editor visuals
          indent-blankline-nvim # indentation guides
          nvim-cursorline # underlines word & highlight current line
          comment-nvim # toggle comment
          range-highlight-nvim # highlight ranges (:20,+4)
          todo-comments-nvim # highlight todo comments and list them in Trouble
          leap-nvim # faster navigation within a file
          nvim-ufo # better folds
          nvim-surround # surround text objects

          # Utilities
          plenary-nvim # Utility library for lots of plugins
          render-markdown-nvim

          # Completion
          blink-cmp
          blink-cmp-git
          nvim-autopairs
          nvim-ts-autotag

          # Colorscheme
          tokyonight-nvim
        ];
        minimalPlugins = [treesitterWithGrammars] ++ commonPlugins;
        fullPlugins =
          [vimPlugins.nvim-treesitter.withAllGrammars]
          ++ commonPlugins
          ++ (with vimPlugins; [
            # LSP
            nvim-lspconfig
            none-ls-nvim # LSP adapter for other plugins (formatter, linter, etc.)
            actions-preview-nvim # preview code actions
            nui-nvim # UI backend for actions-preview
            (plugin "fidget-nvim") # LSP status fidget
            inc-rename-nvim # in-place rename preview

            # Today always require a `.config/nvim/after` to exist which is annoying.
            (plugin "tree-sitter-language-injection-nvim")

            # Rust
            crates-nvim # Show current version of rust dependencies within Cargo.toml
            rustaceanvim # Rust integration
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
              ${lib.strings.fileContents ./tree-sitter.lua}
              ${lib.strings.fileContents ./cmp.lua}
              ${lib.strings.fileContents ./lsp.lua}
              ${lib.strings.fileContents ./ui.lua}
              ${lib.strings.fileContents ./editor.lua}
              EOF
            ''
          ];
        mkPackage = {minimal ? false}:
          wrapNeovim neovim-unwrapped {
            viAlias = true;
            vimAlias = true;
            withPython3 = false;
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
        default = mkPackage {};
        minimal = mkPackage {minimal = true;};
      };
    packages = nixpkgs.lib.genAttrs supportedSystems packagesFor;
  in {
    # make it easy to use this flake as an overlay
    overlays.default = final: prev: {
      neovim = self.packages.${prev.system}.default;
    };

    inherit packages;

    apps = nixpkgs.lib.genAttrs supportedSystems (system: {
      default = {
        type = "app";
        program = "${packages.${system}.default}/bin/nvim";
        meta.description = "Finistere's Neovim distribution";
      };
      minimal = {
        type = "app";
        program = "${packages.${system}.minimal}/bin/nvim";
        meta.description = "Finistere's Neovim distribution without language servers";
      };
    });
  };
}
