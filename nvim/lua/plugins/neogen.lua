vim.pack.add({
    { src = "https://github.com/danymat/neogen" },
})

require("neogen").setup({
    enabled = true,
    input_after_comment = true,
})

local opts = { noremap = true, silent = true }
vim.api.nvim_set_keymap("n", "<Leader>ng", ":lua require('neogen').generate({ type = 'file' })<CR>", opts)

vim.api.nvim_set_keymap("n", "<Leader>nc", ":lua require('neogen').generate({ type = 'class' })<CR>", opts)

vim.api.nvim_set_keymap("n", "<Leader>nf", ":lua require('neogen').generate({ type = 'func' })<CR>", opts)

vim.api.nvim_set_keymap("n", "<Leader>nt", ":lua require('neogen').generate({ type = 'type' })<CR>", opts)
