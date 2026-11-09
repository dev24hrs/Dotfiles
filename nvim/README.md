# Neovim Configuration

A Neovim 0.12 configuration built on the native `vim.pack` plugin manager, with first-class support for Go, Rust, Python, Lua, TypeScript, shell, SQL, and
Markdown.

The simplest way to understand any plugin is still to read its own `README.md`. This document describes how **this configuration** wires plugins together and
which keys/commands it exposes.

![Neovim](https://github.com/dev24hrs/Dotfiles/blob/main/img/nvim_tmux.png?raw=true)

Last verified against `nvim-pack-lock.json`: 2026-11-01 (Neovim 0.12.6, 29 installed plugins).

## Overview

- **Native plugin management** — `vim.pack.add()` installs and loads plugins; `nvim-pack-lock.json` pins revisions. `:PackUI` opens a floating manager for
  updates, lockfile sync, and removal.
- **Native Neovim 0.12 UI** — `vim._core.ui2` provides the centered cmdline and message window; LSP progress and desktop notifications are rendered natively.
- **Custom statusline and tabline** — written from scratch in `lua/config/statusline.lua` and `lua/config/tabline.lua`; they are not plugins.
- **Per-server LSP configs** — 13 servers in `lsp/`, enabled through `vim.lsp.enable()`; no `nvim-lspconfig` dependency.
- **Custom Go tooling** — tests, benchmarks, coverage, interface stubs, mocks, and struct tags live in `ftplugin/go/`.
- **Personal snippets** — VSCode-style snippets in `snippets/`, loaded by blink.cmp.

## Requirements & Installation

### Neovim

Neovim **0.12 or newer** is required. The config uses `vim.pack`, `vim.lsp.enable`, `vim.hl.on_yank`, and `vim._core.ui2`; it is verified on 0.12.6.

A Nerd Font is recommended for the alpha dashboard, devicons, statusline, tabline, and diagnostic signs. Image preview additionally requires a terminal that
implements the Kitty graphics protocol.

### External tools

Plugins and LSPs are not the only dependencies. Install the editor-level tools first:

| Tool                  | Install                            | Used by                                    |
| --------------------- | ---------------------------------- | ------------------------------------------ |
| `git`                 | `brew install git`                 | `vim.pack`, gitsigns                       |
| `ripgrep`             | `brew install ripgrep`             | `grepprg`, fzf-lua live grep               |
| `fzf`                 | `brew install fzf`                 | fzf-lua                                    |
| `imagemagick`         | `brew install imagemagick`         | image.nvim `magick_cli` processor          |
| `curl`                | `brew install curl`                | image.nvim remote image downloads          |
| `go`                  | `brew install go`                  | Go tooling, `go install`                   |
| `gopls`               | `brew install gopls`               | Go LSP (intentionally not Mason-managed)   |
| `lua-language-server` | `brew install lua-language-server` | Lua LSP (intentionally not Mason-managed)  |
| `rust-analyzer`       | `brew install rust-analyzer`       | Rust LSP (intentionally not Mason-managed) |
| `node`                | `brew install node`                | Mason-installed npm-based servers          |
| `python`              | `brew install python`              | Python tooling                             |
| `fish`                | `brew install fish`                | `fish_indent` and the `fish` linter        |
| Xcode CLI tools       | `xcode-select --install`           | sourcekit-lsp on macOS                     |

Go helper binaries used by `ftplugin/go/`:

```bash
go install github.com/cweill/gotests/gotests@latest
go install github.com/josharian/impl@latest
go install github.com/fatih/gomodifytags@latest
go install go.uber.org/mock/mockgen@latest
```

Rust components for formatting and diagnostics:

```bash
rustup component add rustfmt clippy
```

Everything else is managed by Mason (`:Mason`): yaml-language-server, json-lsp, bash-language-server, fish-lsp, sqls, marksman, pyright, stylua, goimports,
gofumpt, oxfmt, sqlfmt, ruff, shfmt, yamlfmt, tombi, oxlint, selene, shellcheck, yamllint, jsonlint, sqlfluff, markdownlint, and delve. `delve` is installed but
no DAP plugin or debug adapter is configured.

### Health checks

- `:checkhealth` — Neovim-wide health.
- `:checkhealth vim.lsp` — enabled servers and client errors.
- `:Mason` — managed LSP/formatter/linter installations.
- `:PackUI` — installed plugins, pending updates, and lockfile state.

## Directory Structure

```text
~/.config/nvim -> ~/Dotfiles/nvim/
├── init.lua                  # Entry point: basic -> config -> plugins -> config.pack
├── lua/
│   ├── basic/                # options, global keymaps, autocmds
│   ├── config/               # LSP, diagnostics, folding, indent, statusline, tabline,
│   │                         # fileheader, :PackUI, native ui2 extensions
│   └── plugins/              # vim.pack specs and per-plugin setup
├── ftplugin/go/              # Go tooling: tests, benchmarks, coverage, mocks, tags, impl
├── lsp/                      # one config per LSP server (13 files)
├── snippets/                 # personal VSCode-style snippets
├── tasks/                    # development notes
└── nvim-pack-lock.json       # pinned plugin revisions
```

## Supported Languages

The table is derived from `vim.lsp.enable()` in `lua/config/lsp.lua`, the filetypes declared in `lsp/*.lua`, `formatters_by_ft` in `lua/plugins/conform.lua`,
and `linters_by_ft` in `lua/plugins/lint.lua`.

| Language              | Filetypes                         | LSP             | Formatter(s)                                       | Linter                                  |
| --------------------- | --------------------------------- | --------------- | -------------------------------------------------- | --------------------------------------- |
| Go                    | `go`, `gomod`, `gowork`, `gotmpl` | `gopls`         | `goimports` then `gofumpt` (`go` only)             | `golangci-lint` (`go` only)             |
| Rust                  | `rust`                            | `rust_analyzer` | `rustfmt` (LSP fallback)                           | Clippy via rust-analyzer                |
| Python                | `python`                          | `pyright`       | `ruff_organize_imports`, `ruff_format`, `ruff_fix` | `ruff`                                  |
| Lua                   | `lua`                             | `lua_ls`        | `stylua`                                           | `selene`                                |
| JavaScript            | `javascript`, `javascriptreact`   | `oxlint`        | `oxfmt`                                            | `oxlint`                                |
| TypeScript            | `typescript`, `typescriptreact`   | `oxlint`        | `oxfmt`                                            | `oxlint`                                |
| JSON / JSONC          | `json`, `jsonc`                   | `jsonls`        | `oxfmt`                                            | `jsonlint`                              |
| YAML                  | `yaml`                            | `yamlls`        | `yamlfmt`                                          | `yamllint`                              |
| TOML                  | `toml`                            | `tombi`         | `tombi`                                            | — (LSP diagnostics)                     |
| Bash / Shell          | `bash`, `sh`                      | `bashls`        | `shfmt`                                            | `shellcheck` (`sh` only)                |
| Fish                  | `fish`                            | `fish_lsp`      | `fish_indent`                                      | `fish`                                  |
| SQL                   | `sql`, `mysql`                    | `sqls`          | `sqlfmt` (`sql` only)                              | `sqlfluff --dialect=mysql` (`sql` only) |
| Markdown              | `markdown`                        | `marksman`      | `oxfmt`                                            | `markdownlint`                          |
| Swift                 | `swift`                           | `sourcekit`     | —                                                  | sourcekit diagnostics                   |
| C / C++ / Objective-C | `c`, `cpp`, `objc`, `objcpp`      | `sourcekit`     | —                                                  | sourcekit diagnostics                   |
| Vue / Svelte / Astro  | `vue`, `svelte`, `astro`          | `oxlint`        | —                                                  | `oxlint`                                |
| HTML / CSS            | `html`, `css`                     | —               | `oxfmt`                                            | —                                       |
| Dockerfile            | `dockerfile`                      | —               | —                                                  | —                                       |

Notes:

- `trim_whitespace` runs for every filetype as the `_` fallback in conform.
- `pyright` is configured with `analysis.ignore = { "*" }`; it provides navigation, completion, and inlay hints, while `ruff` is the actual Python linter.
- `oxlint` is a linter exposed through the LSP protocol; type-aware mode requires `tsgolint` plus TypeScript in the project's `.oxlintrc.json`, and `tsgolint`
  is not installed.
- Rust diagnostics come from rust-analyzer's `check = "clippy"`, not from nvim-lint.
- `sourcekit` is enabled unconditionally and requires macOS with Xcode command-line tools.
- `tsx` files are mapped to the `typescript` filetype; there is no separate TSX filetype, and TypeScript-family files use `oxlint` as their LSP.
- Files larger than 1.5 MB skip LSP, treesitter folding, and other heavy features (see `lua/basic/autocmds.lua`).

### UI & Appearance

#### alpha-nvim

[alpha-nvim](https://github.com/goolord/alpha-nvim) — defined in `lua/plugins/alpha.lua`. Provides the start screen: ASCII art, time-based greeting and date, a
random quote, and dashboard buttons.

| Dashboard key | Action                                               |
| ------------- | ---------------------------------------------------- |
| `f`           | `:FzfLua files`                                      |
| `r`           | `:FzfLua oldfiles`                                   |
| `h`           | Dotfiles picker (`:FzfLua files cwd=~/.config/nvim`) |
| `q`           | `:qa`                                                |

Commands: `:Alpha`, `:AlphaRedraw`, `:AlphaRemap`. The statusline and tabline stay hidden on alpha buffers.

#### gruvbox.nvim

[gruvbox.nvim](https://github.com/ellisonleao/gruvbox.nvim) — defined in `lua/plugins/theme.lua`. Loads the `gruvbox` colorscheme with soft contrast,
transparent background, terminal colors, italics, undercurl/underline/strikethrough, and inverted signs. No custom keymaps; switch with `:colorscheme gruvbox`.

#### hlchunk.nvim

[hlchunk.nvim](https://github.com/shellRaining/hlchunk.nvim) — defined in `lua/plugins/indent.lua`. Draws chunk and indent guides (`│`, highlight `#806d9c`).
Line-number and blank-line chunks are disabled.

Commands: `:EnableHLChunk`, `:DisableHLChunk`, `:EnableHLIndent`, `:DisableHLIndent`. No custom keymaps.

#### which-key.nvim

[which-key.nvim](https://github.com/folke/which-key.nvim) — defined in `lua/plugins/whichKey.lua`. Uses the `modern` preset and shows keybinding hints after a
prefix.

| Key         | Action                                                      |
| ----------- | ----------------------------------------------------------- |
| `<leader>?` | `which-key.show({ global = false })` — buffer-local keymaps |

Command: `:WhichKey [mode] [keys]`.

#### nvim-web-devicons

[nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) — a shared icon dependency, declared in `lua/plugins/alpha.lua`, `fzf.lua`, `nvimTree.lua`,
and `whichKey.lua`. It is also used directly by the custom statusline and tabline. No keymaps or commands.

#### plenary.nvim

[plenary.nvim](https://github.com/nvim-lua/plenary.nvim) — a Lua utility dependency for alpha-nvim, nvim-spectre, and todo-comments.nvim search. No keymaps or
commands.

### Completion & Editing

#### blink.cmp

[blink.cmp](https://github.com/saghen/blink.cmp) — defined in `lua/plugins/blink.lua`. Completion engine with LSP, snippets, buffer, and path sources. Setup is
deferred until `InsertEnter`, `CmdlineEnter`, or `LspAttach` (once). Ghost text, signature help on trigger characters, and cmdline completion are enabled.

| Mode    | Key                | Action                                                |
| ------- | ------------------ | ----------------------------------------------------- |
| insert  | `<C-space>`        | Show menu and documentation                           |
| insert  | `<CR>`             | Accept selection, fall back to newline                |
| insert  | `<Tab>`            | Select next, then snippet forward, then fallback      |
| insert  | `<S-Tab>`          | Select previous, then snippet backward, then fallback |
| insert  | `<Up>` / `<C-k>`   | Select previous                                       |
| insert  | `<Down>` / `<C-j>` | Select next                                           |
| insert  | `<Esc>`            | Cancel completion                                     |
| cmdline | `<CR>`             | Select and accept                                     |
| cmdline | `<Space>`          | Select and accept                                     |

Commands: `:BlinkCmp status`, `:BlinkCmp build`, `:BlinkCmp build-log`. `:BlinkCmp build` builds the optional Rust fuzzy matcher. The snippet source reads
`snippets/` only; friendly-snippets is disabled. `lua/basic/keymaps.lua` also maps insert-mode `<S-Tab>` to outdent; while the completion menu is open, blink
uses it to select the previous item instead.

#### friendly-snippets

[friendly-snippets](https://github.com/rafamadriz/friendly-snippets) — installed in `lua/plugins/blink.lua` but **not used**: the blink snippet provider sets
`friendly_snippets = false` and searches only `snippets/`. No keymaps or commands. It can be removed without changing completion behavior.

#### Comment.nvim

[Comment.nvim](https://github.com/numToStr/Comment.nvim) — defined in `lua/plugins/comment.lua`. Toggles line and block comments; `commentstring` falls back to
`//%s` for unsupported filetypes.

| Mode   | Key     | Action                                 |
| ------ | ------- | -------------------------------------- |
| normal | `<C-.>` | Toggle line comment                    |
| normal | `<C-;>` | Toggle block comment                   |
| visual | `<C-.>` | Toggle line comment for the selection  |
| visual | `<C-;>` | Toggle block comment for the selection |

The plugin's own basic/extra mappings are disabled; only the mappings above are active. No user commands.

#### mini.pairs

[mini.pairs](https://github.com/nvim-mini/mini.pairs) — defined in `lua/plugins/comment.lua`. Auto-closes brackets, quotes, and backticks in insert mode, with
automatic `<BS>` and `<CR>` handling. These are plugin defaults; no project-specific keymaps or commands.

#### mini.surround

[mini.surround](https://github.com/nvim-mini/mini.surround) — defined in `lua/plugins/comment.lua` with default settings. Add, delete, replace, find, and
highlight surrounding characters.

| Mode            | Key         | Action                        |
| --------------- | ----------- | ----------------------------- |
| normal / visual | `sa`        | Add surrounding               |
| normal          | `sd`        | Delete surrounding            |
| normal          | `sr`        | Replace surrounding           |
| normal          | `sf` / `sF` | Find surrounding right / left |
| normal          | `sh`        | Highlight surrounding         |

Suffixes `l` (previous) and `n` (next) are supported by the plugin. These are plugin defaults, not project mappings. Because `s*` mappings exist, a bare `s`
also waits for `timeoutlen` before flash.nvim's `s` jump fires.

#### conform.nvim

[conform.nvim](https://github.com/stevearc/conform.nvim) — defined in `lua/plugins/conform.lua`. Async formatting with LSP fallback. Format-on-save is enabled
unless the path contains `/node_modules/`, `/.git/`, or `/vendor/`.

| Mode            | Key         | Action                                      |
| --------------- | ----------- | ------------------------------------------- |
| normal / visual | `<leader>w` | Format asynchronously, then `silent update` |

The visual-mode mapping still formats the whole buffer, not only the selection. Command: `:ConformInfo`. Formatter chains are listed in
[Supported Languages](#supported-languages).

#### nvim-lint

[nvim-lint](https://github.com/mfussenegger/nvim-lint) — defined in `lua/plugins/lint.lua`. Runs on `BufReadPost` and `BufWritePost` and configures async
linters per filetype: `golangcilint`, `selene`, `shellcheck`, `yamllint`, `jsonlint`, `sqlfluff`, `ruff`, `markdownlint`, and `fish`. No custom keymaps. A
manual pass is available with `:lua require("lint").try_lint()`.

### Search & Navigation

#### fzf-lua

[fzf-lua](https://github.com/ibhagwan/fzf-lua) — defined in `lua/plugins/fzf.lua`. Fuzzy file, buffer, grep, help, mark, and recent-file pickers;
`vim.ui.select` is routed through fzf-lua on `VimEnter`.

| Key          | Action                    |
| ------------ | ------------------------- |
| `<leader>fl` | Find project files        |
| `<leader>fw` | Search the current buffer |
| `<leader>fg` | Live grep in the project  |
| `<leader>fr` | Recent files              |
| `<leader>fb` | Buffers                   |
| `<leader>fh` | Help tags                 |
| `<leader>fm` | Marks                     |

Command: `:FzfLua <picker>`. LSP-integrated pickers are bound in `lua/config/lsp.lua`. Requires `fzf` and `ripgrep`.

#### nvim-spectre

[nvim-spectre](https://github.com/nvim-pack/nvim-spectre) — defined in `lua/plugins/spectre.lua`. Project-wide and file-scoped search/replace.

| Mode   | Key          | Action                                    |
| ------ | ------------ | ----------------------------------------- |
| normal | `<leader>sw` | Search selected word project-wide         |
| visual | `<leader>sw` | Search the current selection project-wide |
| normal | `<leader>sp` | Search and replace in the current file    |

Panel keys: `<Tab>` / `<S-Tab>` switch queries, `o` opens a result, `<CR>` replaces the current line, `<S-CR>` replaces all. Command:
`:Spectre [path] [key=value ...]`. The panel opens in a 60-column vertical split.

#### nvim-tree.lua

[nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua) — defined in `lua/plugins/nvimTree.lua`. Floating file explorer with git status, devicons, and
filters.

| Scope       | Key         | Action                     |
| ----------- | ----------- | -------------------------- |
| global      | `<leader>e` | Toggle the tree            |
| tree buffer | `l` / `e`   | Edit or open the node      |
| tree buffer | `h`         | Close the parent directory |
| tree buffer | `-` / `s`   | Disabled (unmapped)        |

The plugin's default mappings remain available, including `a` create, `d` delete, `r` rename, `y` copy name, `Y` copy relative path, `<Tab>` preview, and `g?`
help. The tree floats at 30% width and 60% height, closes on focus loss, and closes after opening a file. Commands: `:NvimTreeToggle`, `:NvimTreeOpen`,
`:NvimTreeClose`, `:NvimTreeFocus`, `:NvimTreeFindFile`, and the rest of the plugin's command set.

#### aerial.nvim

[aerial.nvim](https://github.com/stevearc/aerial.nvim) — defined in `lua/plugins/aerial.lua`. Code outline backed by treesitter/LSP, with a 30-column right-side
panel.

| Scope         | Key          | Action                 |
| ------------- | ------------ | ---------------------- |
| global        | `<leader>ot` | Toggle outline         |
| aerial buffer | `o`          | Jump to symbol         |
| aerial buffer | `{` / `}`    | Previous / next symbol |
| aerial buffer | `l` / `h`    | Open / close tree node |
| aerial buffer | `q`          | Close outline          |

Commands: `:AerialToggle`, `:AerialOpen`, `:AerialClose`, `:AerialNext`, `:AerialPrev`, `:AerialGo`, `:AerialInfo`.

#### flash.nvim

[flash.nvim](https://github.com/folke/flash.nvim) — defined in `lua/plugins/flash.lua`. Fast character and treesitter jumps with rainbow labels.

| Mode                               | Key | Action                |
| ---------------------------------- | --- | --------------------- |
| normal / visual / operator-pending | `s` | Flash jump            |
| normal / visual / operator-pending | `S` | Flash treesitter node |

Character mode is enabled, so native `f`/`F`/`t`/`T` motions get jump labels too. No custom commands.

#### todo-comments.nvim

[todo-comments.nvim](https://github.com/folke/todo-comments.nvim) — defined in `lua/plugins/todo.lua`. Highlights TODO/FIXME/NOTE/WARN/TEST markers and jumps
between them. Signs are disabled; setup is deferred until the first buffer.

| Key          | Action                 |
| ------------ | ---------------------- |
| `]t`         | Next TODO comment      |
| `[t`         | Previous TODO comment  |
| `<leader>ft` | List TODOs via fzf-lua |

Commands: `:TodoFzfLua`, `:TodoQuickFix`, `:TodoLocList`. The plugin also defines `:TodoTelescope` and `:TodoTrouble`, but those integrations are not installed.

### Git

#### gitsigns.nvim

[gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) — defined in `lua/plugins/git.lua`. Git diff signs in the sign column, current-line blame, and hunk
operations.

| Key  | Action        |
| ---- | ------------- |
| `]g` | Next hunk     |
| `[g` | Previous hunk |

Command: `:Gitsigns <action>`, e.g. `:Gitsigns preview_hunk`, `:Gitsigns stage_hunk`, `:Gitsigns blame_line`, `:Gitsigns toggle_current_line_blame`.

### Treesitter & Tooling

#### nvim-treesitter

[nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) — defined in `lua/plugins/treesitter.lua`, pinned to the `main` branch with `:TSUpdate` as
its build hook. Setup and parser installation are deferred until the first buffer. Configured parsers: `bash`, `fish`, `go`, `gomod`, `gosum`, `gowork`,
`gotmpl`, `rust`, `sql`, `python`, `typescript`, `javascript`, `tsx`, `json`, `toml`, `html`, `yaml`, `dockerfile` (plus the Neovim 0.12 defaults for Lua, Vim,
Vimdoc, Markdown). Commands: `:TSInstall`, `:TSUpdate`, `:TSUninstall`, `:TSLog`. No project-specific keymaps in this file. Every buffer whose filetype has a
Treesitter parser gets the Treesitter `indentexpr`; buffers without a parser keep their existing indentation.

#### nvim-treesitter-textobjects

[nvim-treesitter-textobjects](https://github.com/nvim-treesitter/nvim-treesitter-textobjects) — defined in `lua/plugins/treesitter.lua`, pinned to `main`.
Treesitter-based selection and movement.

| Mode                               | Key         | Textobject                              |
| ---------------------------------- | ----------- | --------------------------------------- |
| visual / operator-pending          | `fo`        | `@function.outer`                       |
| visual / operator-pending          | `fi`        | `@function.inner`                       |
| visual / operator-pending          | `co`        | `@class.outer`                          |
| visual / operator-pending          | `ci`        | `@class.inner`                          |
| visual / operator-pending          | `po`        | `@parameter.outer`                      |
| visual / operator-pending          | `pi`        | `@parameter.inner`                      |
| normal / visual / operator-pending | `]f` / `[f` | Next / previous `@function.outer` start |
| normal / visual / operator-pending | `]c` / `[c` | Next / previous `@class.outer` start    |
| normal / visual / operator-pending | `]]` / `[[` | Next / previous `@function.outer` end   |
| normal / visual / operator-pending | `]l` / `[l` | Next / previous `@loop` start           |

Selection modes are `v` for parameters, `V` for functions, and `<C-v>` for classes. The operator-pending `ci`/`co` mappings shadow Vim's built-in change-inside
prefix (for example `ciw` or `ci"`); disable these mappings if you rely on those combinations. `]]`/`[[` also override Vim's section motions.

#### nvim-treesitter-context

[nvim-treesitter-context](https://github.com/nvim-treesitter/nvim-treesitter-context) — installed in `lua/plugins/treesitter.lua` with plugin defaults. Pins the
enclosing function/class header at the top of the window while scrolling. Command: `:TSContext enable|disable|toggle`. No custom keymaps or setup overrides.

#### mason.nvim

[mason.nvim](https://github.com/mason-org/mason.nvim) — defined in `lua/plugins/mason.lua`. Installs and updates LSP servers, formatters, and linters. The
configured `ensure_installed` list is installed asynchronously after startup; unknown packages are reported with a warning.

Commands: `:Mason`, `:MasonInstall <name>`, `:MasonUninstall <name>`, `:MasonUninstallAll`, `:MasonUpdate`, `:MasonLog`. No keymaps. gopls, lua-language-server,
and rust-analyzer are deliberately installed with Homebrew instead of Mason. `delve` is installed, but this config has no DAP plugin, so no debugging UI is
available.

#### lazydev.nvim

[lazydev.nvim](https://github.com/folke/lazydev.nvim) — defined in `lua/plugins/lazydev.lua`. Extends lua_ls with the `vim.pack` `opt` plugin directory so
Neovim and plugin APIs resolve correctly. Command: `:LazyDev`. No custom keymaps.

### Language-Specific

#### crates.nvim

[crates.nvim](https://github.com/saecki/crates.nvim) — defined in `lua/plugins/crates.lua`, pinned to the `stable` tag. Adds Cargo.toml completions, crate
documentation, version info, and inline actions through Neovim's built-in LSP. Setup is deferred until a `Cargo.toml` buffer loads. No custom keymaps.

Command: `:Crates <subcommand>`, e.g. `:Crates show`, `:Crates update`, `:Crates upgrade_crate`, `:Crates open_documentation`.

#### render-markdown.nvim

[render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim) — defined in `lua/plugins/markdown.lua`. Renders Markdown in the editor:
headings, bullet icons, checkboxes, pipe tables, link icons, and code-block signs. LaTeX rendering is disabled; anti-conceal is disabled in normal mode. No
custom keymaps.

Command: `:RenderMarkdown [enable|disable|toggle|buf_enable|buf_disable|buf_toggle|preview]`.

#### image.nvim

[image.nvim](https://github.com/3rd/image.nvim) — defined in `lua/plugins/markdown.lua`. Inline image rendering for Markdown using the Kitty graphics protocol
(`backend = "kitty"`, `kitty_method = "normal"`) and ImageMagick (`processor = "magick_cli"`). Remote images are downloaded with curl. Command: `:ImageReport`.
No custom keymaps. Rendering requires a compatible terminal; images are cleared in insert mode.

## Custom Configuration

Every custom module is listed below. The `lua/basic` layer runs before plugins; `lua/config` runs before and after plugin setup as ordered by `init.lua`.

### lua/basic/options.lua

Sets plugin-independent editor options: system clipboard, persistent undo, no swap/backup files, `updatetime = 250`, `timeoutlen = 300`, mouse support, relative
numbers, `cmdheight = 0` for the ui2 cmdline, `winborder = "single"`, `signcolumn = "number"`, `inccommand = "nosplit"`, `completeopt`, search settings,
`grepprg = "rg --vimgrep --no-heading"`, `splitright`, and disabled netrw. It also enables the bundled `nvim.undotree` via `packadd` and maps `gotmpl`, `mdx`,
`tsx`, `LICENSE`, `.yamllint`, and `.yamlfmt` filetypes. No keymaps or commands.

### lua/basic/keymaps.lua

Global editing keymaps. `<Space>` is set as both leader and localleader.

| Mode            | Key          | Action                                                  |
| --------------- | ------------ | ------------------------------------------------------- |
| normal          | `<Esc>`      | Clear search highlight                                  |
| insert          | `<S-Tab>`    | Outdent (`<C-d>`)                                       |
| visual          | `<` / `>`    | Indent/outdent and keep the selection                   |
| visual          | `J` / `K`    | Move the selection down / up                            |
| normal / visual | `W` / `E`    | Jump to line start / end                                |
| normal          | `wq`         | Write and quit                                          |
| normal          | `j` / `k`    | Move by screen line (`gj`/`gk`)                         |
| normal          | `<leader>cp` | Copy the relative file path                             |
| visual          | `<leader>cp` | Copy the relative file path plus `start:end` line range |

`<leader>cp` optionally prompts for a note and writes the reference to the `+` register, ready to paste into a chat.

### lua/basic/autocmds.lua

Core autocommands and `:H`:

- `TextYankPost` highlights yanked text for 500 ms.
- A global `FileType` hook removes `c`, `r`, and `o` from `formatoptions`, stopping automatic comment continuation.
- `BufReadPost` restores the last cursor position.
- Markdown buffers get `textwidth = 120`, wrapping, and `conceallevel = 0`.
- Help, quickfix, checkhealth, spectre, undotree, and similar buffers become unlisted and close with `q`.
- Files larger than 1.5 MB disable folds, spell, list, swap, and persistent undo; attached LSP clients are stopped.

Command: `:H [topic]` opens help in an 80-column vertical split with a fixed width.

### lua/config/diagnostic.lua

Configures `vim.diagnostic`: rounded floating windows up to 80 columns, diagnostics sorted by severity, no updates in insert mode, underlines only for errors,
virtual text with source/code, and `E`/`W`/`I`/`H` signs (error/warning signs also recolor the line number). No keymaps or commands.

### lua/config/fileheader.lua

Inserts a copyright/author header into empty buffers. Templates exist for Lua, Go, Rust, TypeScript, and Python. Placeholders are filled from the date,
filename, and `git config user.name`/`user.email`. The `BufNewFile` and `BufReadPost` autocmds only act on empty buffers; existing content is never overwritten.
Go filenames are sanitized into valid identifiers. Command: `:FileHeader` (manual insertion). No keymaps.

### lua/config/folding.lua

Treesitter-expression folding with a custom fold text that keeps syntax highlighting and appends an `N lines folded` marker.

| Key  | Action                                  |
| ---- | --------------------------------------- |
| `zf` | Toggle the fold under the cursor (`za`) |
| `zr` | Unfold all (`zR`)                       |
| `zm` | Fold all (`zM`)                         |

`foldcolumn` is 0 and folds start fully open. No commands.

### lua/config/langIndent.lua

Per-language indentation applied through a `FileType` autocmd:

- 2 spaces, expand tabs: `json`, `jsonc`, `yaml`, `markdown`, `sh`, `toml`, `sql`, `gitcommit`, `javascript`, `typescript`.
- 4 spaces, expand tabs: `c`, `cpp`, `python`, `lua`, `rust`, `swift`.
- 4-column real tabs, no expand: `go`.

No keymaps or commands.

### lua/config/lsp.lua

Enables 13 servers — `lua_ls`, `gopls`, `pyright`, `rust_analyzer`, `yamlls`, `jsonls`, `bashls`, `fish_lsp`, `sqls`, `marksman`, `tombi`, `sourcekit`, and
`oxlint` — using the per-server configs in `lsp/`. On `LspAttach` it adds buffer-local mappings, enables document color (`virtual` style), and enables inlay
hints when the server supports them.

| Key          | Action                     |
| ------------ | -------------------------- |
| `<leader>cr` | Rename symbol              |
| `K`          | Hover documentation        |
| `gd`         | Go to definition           |
| `gi`         | Go to implementation       |
| `gt`         | Go to type definition      |
| `<leader>ca` | Code actions via fzf-lua   |
| `gr`         | References via fzf-lua     |
| `gf`         | LSP finder via fzf-lua     |
| `<leader>ci` | Incoming calls             |
| `<leader>co` | Outgoing calls             |
| `<leader>dc` | Current buffer diagnostics |
| `<leader>dw` | Workspace diagnostics      |
| `[d` / `]d`  | Previous / next diagnostic |
| `[e` / `]e`  | Previous / next error      |
| `[w` / `]w`  | Previous / next warning    |

Note that plain `gi`, `gr`, `gt`, and `gd` are LSP maps; the Go tooling maps are `<leader>gi`, `<leader>gr`, etc. These maps are buffer-local and only exist
while an LSP client is attached.

### lua/config/pack.lua

Custom floating manager over the native `vim.pack` API. Command: `:PackUI` opens a centered panel (65% width, 60% height) listing active and inactive plugins,
their URL, and their pinned revision.

| Panel key | Action                                                                     |
| --------- | -------------------------------------------------------------------------- |
| `q`       | Close the panel                                                            |
| `<CR>`    | Expand/collapse a section or plugin details                                |
| `u`       | Update the plugin under the cursor                                         |
| `U`       | Update all plugins                                                         |
| `r`       | Sync the lockfile                                                          |
| `d`       | Delete the plugin under the cursor (inactive plugins only; asks for `y/n`) |

Use it for routine updates instead of editing `nvim-pack-lock.json` by hand. The panel labels are in Chinese.

### lua/config/statusline.lua

A fully custom global statusline (`%!v:lua.statusline()`), activated after the first real file is opened.

- Left: mode, git branch, filename, gitsigns diff counts, and diagnostic counts per severity.
- Right: indent style, encoding, file format (LF/CRLF/CR), filetype with devicon, and attached LSP client names.

Colors follow the gruvbox palette. The statusline is hidden on `alpha`, `dashboard`, and `qf` buffers. No keymaps or commands.

### lua/config/tabline.lua

Custom tabline that lists loaded, listed buffers rather than real tabs. Each entry shows a devicon, `parent/filename`, and a modified marker; overflow is
handled with `« N` / `N »` markers, and left-clicking an entry switches to that buffer.

| Key  | Action                         |
| ---- | ------------------------------ |
| `wh` | Previous buffer                |
| `wl` | Next buffer                    |
| `wd` | Delete the current buffer      |
| `wo` | Close all other listed buffers |

The tabline activates after the first real file. No commands.

### lua/config/ui2_cmd.lua

Extends Neovim 0.12's built-in `vim._core.ui2` command-line UI: enables ui2, centers the floating cmdline (35% width, clamped to 40–80 columns), removes the
message-window border, lifts the message window above the statusline, and repositions blink.cmp's completion menu after layout changes. It contains no keymaps
or commands and relies on Neovim-internal APIs, so it is tied to 0.12.

### lua/config/ui2_lsp.lua

Renders LSP progress natively. `LspProgress` events are emitted as `nvim_echo` progress messages in the ui2 message window, with a 10 Hz braille spinner, stable
per-token message IDs, and done/failed icons. Finished tasks expire naturally; unfinished tasks are re-emitted so ui2's timeout does not hide them. No keymaps
or commands.

### lua/config/ui2_notify.lua

Overrides `vim.notify` with a borderless top-right floating stack. It shows a level icon and title, stacks up to 10 notifications newest-first, caps width at 60
columns, and uses per-level timeouts (3 s default, 4 s warning, 5 s error). Notifications are intentionally not written to `:messages`. No keymaps or commands.

## Go Tooling (ftplugin/go)

Neovim's ftplugin loader sources these files automatically for Go buffers. All commands are global once created; all keymaps are buffer-local and exist only in
Go buffers. Each command saves the buffer before running its external tool asynchronously and guards against concurrent runs.

### ftplugin/go/addtest.lua

Generates table-driven tests with `gotests`. `:GoTestAdd` uses the treesitter function/method under the cursor, an explicit function name, or a prompt as a
fallback.

| Command                 | Action                                                        |
| ----------------------- | ------------------------------------------------------------- |
| `:GoTestAdd [function]` | Generate a test for the cursor function or the named function |
| `:GoTestsAll`           | Generate tests for all functions in the file                  |
| `:GoTestsExp`           | Generate tests for exported functions only                    |

| Key          | Command       |
| ------------ | ------------- |
| `<leader>gt` | `:GoTestAdd`  |
| `<leader>ga` | `:GoTestsAll` |
| `<leader>ge` | `:GoTestsExp` |

Requires `gotests` (`go install github.com/cweill/gotests/gotests@latest`). The generated `_test.go` file is written to disk but not opened.

### ftplugin/go/benchmark.lua

Runs benchmarks with `go test` and shows parsed results in a floating window.

| Command                   | Action                                            |
| ------------------------- | ------------------------------------------------- |
| `:GoBench [name]`         | Run the benchmark under the cursor                |
| `:GoBenchAll [package]`   | Run all benchmarks in the current package         |
| `:GoBenchTime [duration]` | Run the current benchmark with a custom benchtime |
| `:GoBenchClear`           | Stop the benchmark and close the result window    |

Keys: `<leader>gb` (`:GoBench`), `<leader>gB` (`:GoBenchAll`). The result window closes with `q` or `<Esc>`. Requires `go` and a `go.mod`; commands run from the
module root.

### ftplugin/go/coverage.lua

Runs `go test` coverage and marks covered/uncovered lines in the sign column, with per-function statistics in a floating window.

| Command                     | Action                                           |
| --------------------------- | ------------------------------------------------ |
| `:GoCoverage [package]`     | Run coverage (default `./...`)                   |
| `:GoCoverageLoad {profile}` | Load an existing coverage profile                |
| `:GoCoverageClear`          | Stop the job, remove signs, and close the window |

Key: `<leader>gc` (`:GoCoverage`). Covered lines use a green `│` sign, uncovered lines a red `│`; the stats window closes with `q` or `<Esc>`. Requires `go` and
a `go.mod`.

### ftplugin/go/impl.lua

Generates interface-implementation stubs with `impl`. The receiver is derived from the nearest struct above the cursor (for example `File` becomes `f *File`).

| Command               | Action                                 |
| --------------------- | -------------------------------------- |
| `:GoImpl [interface]` | Generate stubs for the given interface |

Key: `<leader>gi` (`:GoImpl`). Requires `impl` (`go install github.com/josharian/impl@latest`) and the Go treesitter parser for struct detection. Output is
inserted after the cursor line.

### ftplugin/go/mock.lua

Generates GoMock mocks with `mockgen`, either from a source file or from an interface.

| Command                           | Action                                             |
| --------------------------------- | -------------------------------------------------- |
| `:GoMockFile [dir]`               | Generate mocks for interfaces in the current file  |
| `:GoMockInterface [name]`         | Generate a mock for the interface under the cursor |
| `:GoMockGen [-s\|-i\|-p\|-d ...]` | Explicit mockgen-style flags                       |

Keys: `<leader>gm` (`:GoMockGen`), `<leader>gM` (`:GoMockFile`). The default destination is `<module-root>/mocks` and the default package is `mocks`;
`-d/--dir`, `-p/--package`, `-i/--interface`, and `-s/--source` are supported. Requires `mockgen` (`go install go.uber.org/mock/mockgen@latest`), `go` for
`go list` import-path resolution, and a `go.mod`. Generated files are written to disk but not opened.

### ftplugin/go/tag.lua

Adds or removes struct tags with `gomodifytags`, using `camelcase` transformations.

| Command              | Action                        |
| -------------------- | ----------------------------- |
| `:GoAddTag [tag]`    | Add a tag (default `json`)    |
| `:GoRemoveTag [tag]` | Remove a tag (default `json`) |

Keys: `<leader>gj` (`:GoAddTag`), `<leader>gr` (`:GoRemoveTag`). Works on the struct at the cursor, saves the buffer first, and reloads it with `:checktime`
afterwards. Requires `gomodifytags` (`go install github.com/fatih/gomodifytags@latest`).

## LSP Server Configurations (lsp/)

`lua/config/lsp.lua` enables these servers by filename; each file below is picked up automatically by Neovim's `lsp/` runtime directory. All servers share the
buffer-local keymaps documented in `lua/config/lsp.lua`.

## Snippets

`snippets/` is the only snippet source used by blink.cmp (`friendly-snippets` is disabled). It follows the VSCode snippet format with a `package.json` registry.

```text
snippets/
├── package.json                 # registry (contributes.snippets)
├── license.json                 # license header snippets
├── sql.json
├── docker/
│   ├── docker-compose.json
│   └── docker-file.json
├── go/
│   ├── go.json
│   ├── map.json
│   ├── slice.json
│   └── sort.json
├── lua/
│   ├── lua.json
│   └── luadoc.json
├── markdown/markdown.json
├── rust/rust.json
└── typescript/typescript.json
```

Typical triggers include `hea` (file header), `struct` (Go struct with JSON tags), `func`, `method`, `ifok`, `lock`, `once`, `wg` (Go), `mod`/`req` (Lua), and
`sort` (Go `slices.Sort`). Snippets are completed through blink.cmp's snippet source.

All paths in `package.json` resolve to files in this directory; the Dockerfile and Docker Compose sets are loaded alongside the language-specific snippet sets.

# License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
