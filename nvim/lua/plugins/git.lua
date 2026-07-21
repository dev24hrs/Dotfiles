vim.pack.add({
    { src = "https://github.com/lewis6991/gitsigns.nvim" },
})

vim.pack.add({
    { src = "https://github.com/esmuellert/codediff.nvim" },
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
        map("n", "]h", function()
            gitsigns.nav_hunk("next")
        end, { desc = "[Gitsigns]: Next Hunk" })
        map("n", "[h", function()
            gitsigns.nav_hunk("prev")
        end, { desc = "[Gitsigns]: Previous Hunk" })

        map("n", "<leader>hp", gitsigns.preview_hunk, { desc = "[Gitsigns]: Preview Hunk" })
        map("n", "<leader>hb", function()
            gitsigns.blame_line({ full = true })
        end, { desc = "[Gitsigns]: Show Blame Line" })
    end,
})
