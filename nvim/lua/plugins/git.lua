-- Copyright (c) 2026 x3m4g63. All rights reserved.
-- The source code is released under the MIT License.
--
--- @module 'git'
--- @author x3m4g63 <asang24dev@gmail.com>
--- @date 2026-11-12
--- @description Gitsigns signs, hunk actions and blame

vim.pack.add({
    { src = "https://github.com/lewis6991/gitsigns.nvim" },
})

require("gitsigns").setup({
    signs = {
        add = { text = "│" },
        change = { text = "│" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "┆" },
    },
    signs_staged = {
        add = { text = "│" },
        change = { text = "│" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "┆" },
    },
    signcolumn = true,
    current_line_blame = true,
    current_line_blame_formatter = "     <author_mail>, <author_time:%Y-%m-%d> • <summary> • <abbrev_sha>",
    on_attach = function(bufnr)
        local gitsigns = require("gitsigns")
        local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
        end
        -- Navigation
        map("n", "]g", function()
            gitsigns.nav_hunk("next")
        end, { desc = "[Gitsigns]: Next Hunk" })
        map("n", "[g", function()
            gitsigns.nav_hunk("prev")
        end, { desc = "[Gitsigns]: Previous Hunk" })
    end,
})
