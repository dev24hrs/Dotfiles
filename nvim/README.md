# Neovim Configuration

A modern Neovim IDE configuration built on the **Neovim 0.12** native plugin manager, with support for Go, Rust, Python, Lua, and more.

The simplest and most effective way is to read the plugin's `readme.md`.

![Neovim](https://github.com/dev24hrs/Dotfiles/blob/main/img/nvim_tmux.png?raw=true)

## Directory Structure

```
~/.config/nvim/
├── init.lua              # Entry point
├── lua/
│   ├── basic/            # Core editor settings (options, keymaps, autocmds, folding, indent)
│   ├── config/           # Advanced configuration (LSP, diagnostics, language-specific tools)
│   └── plugins/          # Plugin configurations
├── lsp/                  # LSP server configurations
└── snippets/             # Code snippets (Go, Rust, Python, Lua, Markdown)
```

## Supported Languages

use brew install `gopls` & `lua-language-server` & `typescript-language-server` & `rust-analyzer`, installed by `homebrew`.

```bash
# gopls
brew install gopls

# lua-language-server
brew install lua luarocks
brew install lua-language-server

# typescript-language-server
brew install node
brew install typescript typescript-language-server

# rust
brew install rust-analyzer
```

| Language              | LSP           | Formatter           | Linter        |
| --------------------- | ------------- | ------------------- | ------------- |
| Go                    | gopls         | goimports + gofumpt | golangci-lint |
| Rust                  | rust-analyzer | rustfmt             | clippy        |
| Python                | pyright       | ruff_format + ruff  | ruff          |
| Lua                   | lua_ls        | stylua              | selene        |
| JavaScript/TypeScript | vtsls         | prettierd           | eslint_d      |
| YAML                  | yamlls        | yamlfmt             | yamllint      |
| JSON                  | jsonls        | prettierd           | jsonlint      |
| Bash                  | bashls        | shfmt               | shellcheck    |
| Fish                  | fish-lsp      | fish_indent         | fish_indent   |
| SQL                   | sqls          | sqlfmt              | sqlfluff      |
| Markdown              | marksman      | prettierd           | markdownlint  |

## Plugin List

### Theme & UI

- [gruvbox.nvim](https://github.com/ellisonleao/gruvbox.nvim) Gruvbox color scheme with transparent background support
- [bufferline.nvim](https://github.com/akinsho/bufferline.nvim) Top buffer tab bar with customizable close behavior
- [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) Status bar showing mode, Git info, indent style, and more
- [which-key.nvim](https://github.com/folke/which-key.nvim) Keybinding hint panel that shows available commands after pressing Leader
- [alpha-nvim](https://github.com/goolord/alpha-nvim) Start screen with custom ASCII art, time, and quotes
- [hlchunk.nvim](https://github.com/shellRaining/hlchunk.nvim) Indent line highlighting to help identify code block nesting

### Editing

- [blink.cmp](https://github.com/saghen/blink.cmp) Next-generation completion engine with LSP, Snippet, and AI support
- [LuaSnip](https://github.com/L3MON4D3/LuaSnip) Snippet engine with VS Code format snippet support
- [Comment.nvim](https://github.com/numToStr/Comment.nvim) Comment/uncomment code with support for line and block comments
- [conform.nvim](https://github.com/stevearc/conform.nvim) Code formatting with auto-format on save, supports 10+ formatters
- [flash.nvim](https://github.com/folke/flash.nvim) Fast cursor jumping,enhances f/F/t/T and Treesitter node navigation
- [mini.pairs](https://github.com/nvim-mini/mini.pairs) Auto-pairing for brackets and quotes

### Search & Navigation

- [fzf-lua](https://github.com/ibhagwan/fzf-lua) Fuzzy finder for files,buffers, help docs, diagnostics, marks, and more
- [nvim-spectre](https://github.com/nvim-pack/nvim-spectre) Project-wide search and replace
- [nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua) File explorer sidebar with floating window mode
- [aerial.nvim](https://github.com/stevearc/aerial.nvim) Code outline for quick navigation of functions, classes, and symbols
- [todo-comments.nvim](https://github.com/folke/todo-comments.nvim) Highlight and jump to TODO/FIXME/NOTE comment markers

### Syntax & LSP

- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) Syntax tree parsing for accurate syntax highlighting and code understanding
- [nvim-treesitter-textobjects](https://github.com/nvim-treesitter/nvim-treesitter-textobjects) Treesitter-based text objects for selecting and jumping by
  function/class
- [nvim-treesitter-context](https://github.com/nvim-treesitter/nvim-treesitter-context) Pins the current function/class context while scrolling
- [lspsaga.nvim](https://github.com/nvimdev/lspsaga.nvim) Enhanced LSP UI with hover docs, reference finder, and call hierarchy
- [mason.nvim](https://github.com/mason-org/mason.nvim) Unified manager for installing LSP servers, formatters, and linters
- [nvim-lint](https://github.com/mfussenegger/nvim-lint) Async linting with golangci-lint, shellcheck, selene, and more
- [fidget.nvim](https://github.com/j-hui/fidget.nvim) LSP progress spinner
- [nvim-notify](https://github.com/rcarriga/nvim-notify) Notification popups replacing the default cmdline notifications
- [noice.nvim](https://github.com/folke/noice.nvim) Revamped UI for the command line, notifications, and popup menus

### Git

- [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) Git change indicators in the sign column with hunk operations and blame

### Language-Specific Tools

- [windsurf.nvim](https://github.com/Exafunction/windsurf.nvim) Codeium AI code completion integrated into blink.cmp
- [gopher.nvim](https://github.com/olexsmir/gopher.nvim) Go helper tools for struct tags, interface generation, and more
- [crates.nvim](https://github.com/saecki/crates.nvim) Smart completion for Rust Cargo.toml with crate version information
- [render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim) Live Markdown rendering with beautified in-editor display
- [image.nvim](https://github.com/3rd/image.nvim) Image preview inside the terminal, used alongside Markdown

### Terminal & Tools

- [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim) Floating terminal, toggle quickly with `Ctrl+T`
- [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) Seamless navigation between Neovim and Tmux panes (`Ctrl+hjkl`)

## Key Bindings

> Leader key is `Space`

### Search (fzf-lua)

| Key          | Action                       |
| ------------ | ---------------------------- |
| `<leader>fl` | Find project files           |
| `<leader>fw` | Search current buffer        |
| `<leader>fg` | Global grep search           |
| `<leader>fr` | Recent files                 |
| `<leader>fb` | Buffer list                  |
| `<leader>fh` | Help docs search             |
| `<leader>fd` | Diagnostics (current file)   |
| `<leader>fp` | Diagnostics (entire project) |
| `<leader>fm` | Marks list                   |
| `<leader>ft` | TODO comment list            |

### LSP

| Key          | Action                |
| ------------ | --------------------- |
| `gd`         | Go to definition      |
| `gi`         | Go to implementation  |
| `gr`         | Find references       |
| `gt`         | Go to type definition |
| `<leader>r`  | Rename symbol         |
| `<leader>,`  | Code actions          |
| `<leader>lf` | LSP finder            |
| `<leader>li` | Incoming calls        |
| `<leader>lo` | Outgoing calls        |
| `<leader>ld` | Buffer diagnostics    |
| `<leader>lw` | Workspace diagnostics |

### Navigation

| Key          | Action                         |
| ------------ | ------------------------------ |
| `s`          | Flash character jump           |
| `S`          | Flash Treesitter node jump     |
| `W`          | Jump to line start             |
| `E`          | Jump to line end               |
| `Shift+h`    | Previous buffer                |
| `Shift+l`    | Next buffer                    |
| `bd`         | Close current buffer           |
| `wh / wl`    | Jump to left/right split       |
| `<leader>co` | Open code outline              |
| `<leader>sw` | Global search and replace      |
| `<leader>sp` | File-scoped search and replace |

### Misc

| Key          | Action                   |
| ------------ | ------------------------ |
| `<leader>w`  | Format and save          |
| `Ctrl+T`     | Toggle floating terminal |
| `Ctrl+.`     | Toggle line comment      |
| `Ctrl+;`     | Toggle block comment     |
| `Escape`     | Clear search highlight   |
| `<leader>fn` | Notification history     |
| `<leader>?`  | Show keybinding hints    |

## Custom Commands

| Command       | Description                   |
| ------------- | ----------------------------- |
| `:H [topic]`  | Open help in a vertical split |
| `:PackClean`  | Remove unused plugins         |
| `:PackUpdate` | Update all plugins            |
| `:LspInfo`    | Show LSP status               |
| `:LspRestart` | Restart LSP servers           |
| `:LspStatus`  | Show detailed LSP status      |

# LICENSE

This project is licensed under the MIT License.
