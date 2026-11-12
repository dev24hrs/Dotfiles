-- Copyright (c) 2026 x3m4g63. All rights reserved.
-- The source code is released under the MIT License.
--
--- @module 'theme'
--- @author x3m4g63 <asang24dev@gmail.com>
--- @date 2026-11-12
--- @description Gruvbox colorscheme and terminal colors

vim.pack.add({
    { src = "https://github.com/ellisonleao/gruvbox.nvim" },
})

require("gruvbox").setup({
    terminal_colors = true, -- add neovim terminal colors
    undercurl = true,
    underline = true,
    bold = true,
    italic = {
        strings = true, -- default is true
        emphasis = true,
        comments = true,
        operators = true,
        folds = true,
    },
    strikethrough = true,
    invert_selection = false,
    invert_signs = true,
    invert_tabline = false,
    invert_intend_guides = false,
    inverse = true, -- invert background for search, diffs, statuslines and errors
    contrast = "soft", -- can be "hard", "soft" or empty string
    palette_overrides = {},
    overrides = {},
    dim_inactive = false,
    transparent_mode = true, -- set true to more beautiful
})
vim.cmd("colorscheme gruvbox")
