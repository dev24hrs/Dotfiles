vim.pack.add({
    { src = "https://github.com/ibhagwan/fzf-lua" },
    { src = "https://github.com/nvim-tree/nvim-web-devicons" },
})
vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
        require("fzf-lua").register_ui_select()
    end,
})

require("fzf-lua").setup({
    winopts = {
        border = "single",
        height = 0.55,
        width = 0.50,
        row = 0.45,
        col = 0.40,
        preview = {
            border = "single",
            horizontal = "right:60%",
            layout = "horizontal",
            wrap = true,
            scrollbar = false,
        },
    },
    fzf_colors = true,
})

vim.keymap.set("n", "<leader>fl", function()
    require("fzf-lua").files()
end, { noremap = true, silent = true, desc = "[Fzf]: Files List in project" })

vim.keymap.set("n", "<leader>fw", function()
    require("fzf-lua").lgrep_curbuf()
end, { noremap = true, silent = true, desc = "[Fzf]: Find Word in current buffer" })

vim.keymap.set("n", "<leader>fg", function()
    require("fzf-lua").live_grep()
end, { noremap = true, silent = true, desc = "[Fzf]: Find Grep words in project" })

vim.keymap.set("n", "<leader>fr", function()
    require("fzf-lua").oldfiles()
end, { noremap = true, silent = true, desc = "[Fzf]: Find Recent files" })

vim.keymap.set("n", "<leader>fb", function()
    require("fzf-lua").buffers()
end, { noremap = true, silent = true, desc = "[Fzf]: Find existing Buffers" })

vim.keymap.set("n", "<leader>fh", function()
    require("fzf-lua").helptags()
end, { noremap = true, silent = true, desc = "[Fzf]: Show Neovim Help Pages" })

vim.keymap.set("n", "<leader>fm", function()
    require("fzf-lua").marks()
end, { noremap = true, silent = true, desc = "[Fzf]: Show Marks" })
