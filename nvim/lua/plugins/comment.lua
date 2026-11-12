-- Copyright (c) 2026 dev24hrs. All rights reserved.
-- The source code is released under the MIT License.
--
--- @module 'comment'
--- @author dev24hrs <asang24dev@gmail.com>
--- @date 2026-11-12
--- @description Comment.nvim plus mini.pairs and mini.surround

vim.pack.add({
    { src = "https://github.com/nvim-mini/mini.pairs" },
    { src = "https://github.com/nvim-mini/mini.surround", version = "stable" },
})
require("mini.pairs").setup()
require("mini.surround").setup()

vim.pack.add({
    { src = "https://github.com/numToStr/Comment.nvim" },
})

---@diagnostic disable-next-line: missing-fields
require("Comment").setup({
    padding = true,
    sticky = true,
    mappings = {
        basic = false,
        extra = false,
    },
})
-- enable commenting for unsupported filetypes in normal file buffers only
local comment_fallback_group = vim.api.nvim_create_augroup("User_CommentFallback", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
    group = comment_fallback_group,
    callback = function(ev)
        local buf = ev.buf
        if vim.bo[buf].buftype == "" and vim.bo[buf].commentstring == "" then
            vim.bo[buf].commentstring = "//%s"
        end
    end,
})

local api = require("Comment.api")
vim.keymap.set("n", "<C-.>", api.toggle.linewise.current, { desc = "[Comment]: Toggle comment line" })
vim.keymap.set("n", "<C-;>", api.toggle.blockwise.current, { desc = "[Comment]: Toggle comment blockwise" })

local esc = vim.api.nvim_replace_termcodes("<ESC>", true, false, true)
vim.keymap.set("x", "<C-.>", function()
    vim.api.nvim_feedkeys(esc, "nx", false)
    api.toggle.linewise(vim.fn.visualmode())
end)

vim.keymap.set("x", "<C-;>", function()
    vim.api.nvim_feedkeys(esc, "nx", false)
    api.toggle.blockwise(vim.fn.visualmode())
end)
