vim.pack.add({
    { src = "https://github.com/stevearc/aerial.nvim" },
})

require("aerial").setup({
    attach_mode = "global",
    backends = { "treesitter", "lsp", "markdown", "man", "asciidoc" },
    disable_max_lines = 5000,
    filter_kind = {
        "Class",
        "Constructor",
        "Enum",
        "Function",
        "Interface",
        "Module",
        "Method",
        "Struct",
    },
    highlight_on_hover = true,
    ignore = { filetypes = { "gomod" } },
    layout = { min_width = 20, width = 30, default_direction = "prefer_right", resize_to_content = true },
    show_guides = true,
    autojump = true,
    lazy_load = true,
    close_on_select = true,
    keymaps = {
        ["o"] = "actions.jump",
        ["{"] = "actions.prev",
        ["}"] = "actions.next",
        ["q"] = "actions.close",
        ["l"] = "actions.tree_open",
        ["h"] = "actions.tree_close",
    },
})
vim.keymap.set("n", "<leader>ll", "<cmd>AerialToggle<CR>", { desc = "[Aerial]: Toggle Outline" })
