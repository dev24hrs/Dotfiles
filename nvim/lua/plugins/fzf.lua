-- Copyright (c) 2026 x3m4g63. All rights reserved.
-- The source code is released under the MIT License.
--
--- @module 'fzf'
--- @author x3m4g63 <asang24dev@gmail.com>
--- @date 2026-11-12
--- @description fzf-lua fuzzy finder for files, buffers and live grep

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
        height = 0.65,
        width = 0.60,
        row = 0.55,
        col = 0.50,
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

local function project_root()
    return vim.fs.root(vim.fn.getcwd(), ".git") or vim.fn.getcwd()
end

vim.keymap.set("n", "<leader>fl", function()
    require("fzf-lua").files({ cwd = project_root() })
end, { noremap = true, silent = true, desc = "[Fzf]: Files List in project" })

vim.keymap.set("n", "<leader>fw", function()
    require("fzf-lua").lgrep_curbuf()
end, { noremap = true, silent = true, desc = "[Fzf]: Find Word in current buffer" })

vim.keymap.set("n", "<leader>fg", function()
    require("fzf-lua").live_grep({ cwd = project_root() })
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
