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
cmp.lua              # Auto-completion (blink.cmp, git, snippets, autopairs)
lsp.lua              # LSP config (servers, null-ls/none-ls, keymaps, format-on-save)
ui.lua               # UI (tokyonight theme, fzf-lua, nvim-tree, bufferline, lualine, floaterm)
editor.lua           # Editor behavior (gitsigns, folds, leap, surround, indentation)
spell/               # Spelling dictionary (en.utf-8.add; .spl files are git-ignored)
.vale.ini            # Prose linting config (currently unused in null-ls)
```

All Lua files are concatenated into a single `customRC` block by Nix (see `mkCustomRC` in `flake.nix`).
There are no cross-file `require()` calls between the project's own files. Each `.lua` file
is self-contained and loaded in this order:

1. `base.vim` (Vimscript, loaded first)
2. `tree-sitter.lua`
3. `cmp.lua`
4. `lsp.lua`
5. `ui.lua`
6. `editor.lua`

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

Defined in `flake.nix`:

- **Language servers:** nil (Nix), rust-analyzer, basedpyright (Python),
  typescript-language-server, bash-language-server, graphql-language-service-cli,
  zls (Zig), clangd (C/C++), taplo (TOML)
- **Formatters/linters via none-ls:** alejandra (Nix), shfmt (Shell, 4-space indent),
  statix (Nix), deadnix (Nix dead code), prettierd (JS/HTML/Markdown),
  clang-format (C/C++/CUDA/proto), buildifier (Bazel BUILD/.bzl, from `bazel-buildtools`)
- **Utilities:** ripgrep, fd, gitMinimal, gh, delta, lf with bat-powered previews

## Per-project configuration

The config is global. Project-specific settings come from **environment variables**, usually
set by a devenv/direnv shell, plus an `.editorconfig`. To keep them out of a project's repo,
put `devenv.nix`, `devenv.yaml`, `.envrc` and `.editorconfig` in the directory **above** the
checkout (`$DEVENV_ROOT` is then that parent), and start `nvim` from inside the shell.

The wrapper *prefixes* `PATH` with the bundled tools. The bundled `clangd` (nixpkgs
`clang-tools`) therefore wins over any `clangd` the project shell provides, so projects
select tool versions through these variables instead:

| Variable | Read by | Effect |
|----------|---------|--------|
| `CLANG_FORMAT` | `lsp.lua` | clang-format binary. Pin it to the version the project's CI uses. |
| `CLANG_FORMAT_CHANGED_LINES_ONLY=1` | `lsp.lua` | On save, format only lines changed vs. `git HEAD` (with jj: `@-`), like `clang-format-diff`. Untracked files are formatted entirely. For c/cpp/cuda/proto it replaces clangd/none-ls formatting. Use it when the codebase isn't clean under that clang-format version, otherwise every save reformats unrelated lines. |
| `CLANGD_FLAGS` | clangd itself (and the nixpkgs clangd wrapper) | Extra clangd flags, e.g. `--query-driver` (see below). |
| `ZLS_CMD` | `lsp.lua` | zls binary. |

`base.vim` indents with 4 spaces by default. A project with another indentation (e.g. Google
style C++: 2 spaces, 80 columns) needs an `.editorconfig`. Neovim's built-in support searches
parent directories up to `root = true`, so it can live next to `devenv.nix`. `max_line_length`
sets `textwidth`, so comments wrap as you type.

### C/C++ with clangd

What `lsp.lua` does:
- Fixed clangd flags: `--background-index --clang-tidy --completion-style=detailed
  --header-insertion=iwyu --function-arg-placeholders=1`. clangd finds `compile_commands.json`
  by walking up from each file (also checking `build/`) or through the project's `.clangd`
  `CompilationDatabase`, and reads `.clang-tidy` / `.clangd` itself.
- Root markers: `.clangd`, `.clang-tidy`, `.clang-format`, `compile_commands.json`,
  `compile_flags.txt`, `configure.ac`, `.git`.
- Files in a Bazel output base (path contains `/_bazel_<user>/<hash>/`, which is where
  go-to-definition into `external/` lands) reuse the running clangd instead of starting one
  rooted at e.g. llvm-project's `.clang-format`. Their diagnostics are hidden because
  clangd resolves the symlinks to the real path, can't link it to an includer's flags,
  and guesses wrong ones, giving spurious errors. Navigation still works.
- `<leader>ch`: switch source/header. Inlay hints are on for all servers.

**Pitfall: the nixpkgs clangd wrapper.** `clang-tools`' `clangd` is a shell script that adds
nix's libc++ and libc headers through `CPLUS_INCLUDE_PATH`/`C_INCLUDE_PATH`, *unless* some
`--query-driver` appears in its arguments or in `$CLANGD_FLAGS`. That's right for projects
built with nix's toolchain, but it breaks projects built with anything else (hermetic Bazel
toolchains, a sysroot, Xcode). The symptom is errors deep in libc++, e.g. `reference to
unresolved using declaration` in `<cstdint>`, or `no type named 'string' in namespace 'std'`.
Fix it with `CLANGD_FLAGS`:
- `--query-driver=` (empty glob) when the compile commands carry explicit `--sysroot` /
  `-isystem` flags (hermetic toolchains), or when the compiler can't run on this machine.
  It disables the wrapper and never executes the compiler.
- `--query-driver=/abs/path/glob*` when clangd should run the compiler to learn its builtin
  system include paths (system gcc/clang outside nix, Xcode clang).

### Setting up a new C++ project

Reference implementation: `~/github/openxla/devenv.nix` (Bazel, hermetic toolchain,
BuildBuddy RBE, clang-format pinned to an old nixpkgs revision).

1. **Compile database.** Add a devenv script that regenerates it with one command:
   - CMake: `cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON`, then symlink
     `build/compile_commands.json` to the checkout root.
   - Meson: it's generated in the build dir automatically; symlink it the same way.
   - Bazel: use the project's own generator if it has one, otherwise
     hedron_compile_commands. Generated headers (protos, tablegen, ...) must exist. Building
     `--output_groups=compilation_prerequisites_INTERNAL_` creates them without compiling objects.
2. **Verify clangd** from the checkout root with the shell's environment:
   `clangd --check=path/to/file.cc 2>&1 | grep -E '^E\['`. Only genuine warnings or
   clang-tidy findings should remain. libc++ errors mean the wrapper pitfall above.
3. **clang-format.** Find the version CI uses and set `CLANG_FORMAT`. If nixpkgs no longer
   has that LLVM (`llvmPackages_17` and older are gone), pin an older nixpkgs revision in
   `devenv.yaml`. Then count the files that aren't clean under it (sampling every 50th):
   `git ls-files '*.cc' '*.h' | awk 'NR%50==0' | while read f; do "$CLANG_FORMAT" --style=file --dry-run -Werror "$f" >/dev/null 2>&1 || echo "$f"; done | wc -l`.
   If any aren't, set `CLANG_FORMAT_CHANGED_LINES_ONLY=1`.
4. **Indentation.** Add an `.editorconfig` that matches `.clang-format` (`IndentWidth`,
   `ColumnLimit`).
5. Run `direnv reload`, then restart nvim from the shell.

Template (`devenv.nix`, next to the checkout):

```nix
{ inputs, pkgs, ... }:
let
  # Same version as CI. For an LLVM removed from nixpkgs, use an older input (see devenv.yaml):
  #   (import inputs.nixpkgs-clang17 { system = pkgs.stdenv.hostPlatform.system; }).llvmPackages_17.clang-tools
  clangFormat = pkgs.llvmPackages_19.clang-tools;
in
{
  packages = [ clangFormat pkgs.cmake pkgs.ninja ];
  env.CLANG_FORMAT = "${clangFormat}/bin/clang-format";
  # Only if the codebase isn't clean under that clang-format version.
  env.CLANG_FORMAT_CHANGED_LINES_ONLY = "1";
  # Only if the project isn't built with nix's toolchain (see the wrapper pitfall).
  env.CLANGD_FLAGS = "--query-driver=";

  scripts.compdb = {
    description = "Regenerate compile_commands.json for clangd.";
    exec = ''
      set -euo pipefail
      cd "$DEVENV_ROOT/<checkout>"
      cmake -S . -B build -G Ninja -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
      ln -sf build/compile_commands.json .
    '';
  };
}
```

`devenv.yaml` (the second input only when pinning an LLVM removed from nixpkgs) and `.envrc`:

```yaml
inputs:
  nixpkgs:
    url: github:cachix/devenv-nixpkgs/rolling
  nixpkgs-clang17:
    url: github:NixOS/nixpkgs/1e7a8f391f1a490460760065fa0630b5520f9cf8
```

```sh
eval "$(devenv direnvrc)"
use devenv
```

`.editorconfig` for Google-style C++:

```ini
root = true

[*.{c,cc,cpp,h,hpp,inc,cu,cuh,proto}]
indent_style = space
indent_size = 2
max_line_length = 80
```

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
| Lua variables | `snake_case` | `default_sources`, `null_ls`, `extra_args` |
| Short locals | Abbreviated | `gs` (gitsigns), `hl`, `bopts` |
| Nix variables | `camelCase` | `extraPackages`, `tsGrammarNames`, `extraMakeWrapperArgs` |
| File names | lowercase, kebab-case for multi-word | `lsp.lua`, `tree-sitter.lua` |

### Import / Require Patterns

```lua
-- Direct setup (most common, ~80% of cases)
require('plugin-name').setup({ ... })

-- Local variable when module is used multiple times
local blink = require('blink.cmp')
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
- **C/C++/CUDA/proto:** `clang-format` (or `$CLANG_FORMAT`); changed lines only with
  `CLANG_FORMAT_CHANGED_LINES_ONLY=1` (see [Per-project configuration](#per-project-configuration))
- **Bazel:** `buildifier` (format + lint)

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
