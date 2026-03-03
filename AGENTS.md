# AGENTS.md

This is a **Nix flake** that builds a fully self-contained, custom Neovim distribution.
It is not a traditional dotfiles repo -- Nix declaratively packages Neovim together with
all plugins, language servers, formatters, linters, and utilities into a single derivation.

Repository: `https://github.com/Finistere/neovim-flake.git`

## Project Structure

```
flake.nix            # THE build file -- Nix flake defining inputs, packages, and wrapNeovim
flake.lock           # Pinned dependency hashes
base.vim             # Core Vim options (tabs, mouse, visuals, filetype-specific settings)
tree-sitter.lua      # Treesitter highlighting, folding, indentation, context
cmp.lua              # Auto-completion (nvim-cmp, copilot, luasnip, autopairs)
lsp.lua              # LSP config (servers, null-ls/none-ls, keymaps, format-on-save)
llm.lua              # Copilot setup
ui.lua               # UI (tokyonight theme, telescope, nvim-tree, bufferline, lualine, floaterm)
editor.lua           # Editor behavior (gitsigns, folds, leap, surround, indentation)
debug.lua            # DAP (Debug Adapter Protocol) configuration
spell/               # Spelling dictionary (en.utf-8.add; .spl files are git-ignored)
.vale.ini            # Prose linting config (currently unused in null-ls)
```

All Lua files are concatenated into a single `customRC` block by Nix (see `flake.nix:174-185`).
There are no cross-file `require()` calls between the project's own files. Each `.lua` file
is self-contained and loaded in this order:

1. `base.vim` (Vimscript, loaded first)
2. `tree-sitter.lua`
3. `cmp.lua`
4. `lsp.lua`
5. `llm.lua`
6. `ui.lua`
7. `editor.lua`

## Build Commands

There is **no Makefile, Justfile, package.json, or test framework**. The entire project is
built through Nix.

| Command | Purpose |
|---------|---------|
| `nix build` | Build the complete Neovim package (outputs to `./result/bin/nvim`) |
| `nix run` | Build and immediately run Neovim |
| `nix flake update` | Update all pinned dependencies |
| `nix flake lock --update-input <name>` | Update a specific input (e.g. `nixpkgs`) |

There are **no tests** in this project. It is a personal configuration, not a library.

## Bundled External Tools

Defined in `flake.nix:83-130`:

- **Language servers:** nil (Nix), rust-analyzer, terraform-ls, pyright, basedpyright,
  typescript-language-server, bash-language-server, lua-language-server,
  graphql-language-service-cli, zls (Zig)
- **Formatters/linters via none-ls:** alejandra (Nix), shfmt (Shell, 4-space indent),
  shellcheck, statix (Nix), deadnix (Nix dead code), prettierd (JS/HTML/Markdown), taplo (TOML)
- **Utilities:** ripgrep, fd, git, gh, delta, ranger

## Version Control

This repo uses both **Git** and **Jujutsu (jj)** (colocated `.jj/` directory).

## Code Style Guidelines

### Indentation

- **Lua files:** 2-space indentation throughout
- **Nix (`flake.nix`):** 2-space indentation (enforced by `alejandra` formatter)
- **Vimscript (`base.vim`):** Flat structure, no deep nesting
- Default tab size is 4 spaces (`base.vim:13`), overridden to 2 for:
  nix, lua, typescript, graphql, javascript, json, fish (`base.vim:66`)

### Strings (Lua)

- Use **single quotes** for all strings: `require('plugin-name')`, not `require("plugin-name")`
- Very few exceptions exist; single quotes dominate

### Trailing Commas

- Include trailing commas in Lua table definitions

### Naming Conventions

| Context | Convention | Examples |
|---------|-----------|----------|
| Lua functions | `snake_case` | `format_on_save`, `attach_keymaps`, `toggle_hlsearch` |
| Lua variables | `snake_case` | `cmp_autopairs`, `null_ls`, `extra_args` |
| Short locals | Abbreviated | `gs` (gitsigns), `cmp`, `dap`, `hl`, `bopts` |
| Nix variables | `camelCase` | `extraPackages`, `tsGrammarNames`, `extraMakeWrapperArgs` |
| File names | lowercase, kebab-case for multi-word | `lsp.lua`, `tree-sitter.lua` |

### Import / Require Patterns

```lua
-- Direct setup (most common, ~80% of cases)
require('plugin-name').setup({ ... })

-- Local variable when module is used multiple times
local cmp = require('cmp')
local null_ls = require('null-ls')

-- Nested module access
local trouble = require('trouble.sources.telescope')
```

### Error Handling

- **Guard clauses with early returns:** `if not results then return end`
- **Nil checks before access:** `if client.server_capabilities.inlayHintProvider then`
- **Environment variable checks:** `if os.getenv("SSH_CONNECTION") ~= nil then`
- **No `pcall`/`xpcall`** is used anywhere
- **No `error()` calls** -- errors are avoided by defensive checks

### Type Annotations

- **None.** No LuaLS `---@param`, `---@return`, or `---@type` annotations are used.
- `.luarc.json` is git-ignored (may be generated locally)

### Comments

- File-level section headers use `--` block style:
  ```lua
  --
  -- LSP
  --
  ```
- Inline comments use `--` with a space
- `TODO:` and `FIXME:` prefixes are used for actionable items
- Commented-out code blocks are preserved for reference (common pattern in config repos)

### Formatting (External Code)

Formatting is handled via none-ls on save, not within this repo's code:

- **Nix:** `alejandra` (auto-format on save)
- **Shell:** `shfmt --indent=4`
- **JS/HTML/Markdown:** `prettierd`
- **TOML:** `taplo`

### Key Vim Settings

- Leader key: `Space`
- `;` and `:` are swapped
- Relative line numbers
- Case-insensitive search (smart case)
- Persistent undo across sessions
- Spell checking enabled (en_US, camelCase-aware)
- Mouse enabled in all modes
- System clipboard integration (`unnamedplus`)
- Colorscheme: `tokyonight-moon`

## Adding a New Plugin

1. If the plugin is **not in nixpkgs** `vimPlugins`, add a flake input:
   ```nix
   new-plugin = {
     url = "github:author/plugin-name";
     flake = false;
   };
   ```
2. Add `(plugin "new-plugin")` (or the nixpkgs name) to `packages.myVimPackage.start` in `flake.nix`
3. Create or update the appropriate `.lua` file with `require('plugin-name').setup({ ... })`
4. Run `nix build` to verify
