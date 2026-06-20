vim.pack.add({
    { src = "https://github.com/numToStr/Comment.nvim" },
})

require("Comment").setup({
    padding = true,
    sticky = true,
    mappings = {
        basic = false,
        extra = false,
    },
})
-- enable commenting for unsupported filetypes
vim.bo.commentstring = "//%s"

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
