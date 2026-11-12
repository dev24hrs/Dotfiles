-- Copyright (c) 2026 dev24hrs. All rights reserved.
-- The source code is released under the MIT License.
--
--- @module 'flash'
--- @author dev24hrs <asang24dev@gmail.com>
--- @date 2026-11-12
--- @description Flash-style jump motions

vim.pack.add({
    { src = "https://github.com/folke/flash.nvim" },
})

local flash = require("flash")
flash.setup({
    label = {
        rainbow = {
            enabled = true,
            shade = 1,
        },
    },
    modes = {
        char = {
            enabled = true, -- 自动接管原生的 f/F/t/T
            jump_labels = true,
        },
    },
})
vim.keymap.set({ "n", "x", "o" }, "s", function()
    flash.jump()
end, { desc = "[Flash]: Flash Jump" })

vim.keymap.set({ "n", "x", "o" }, "S", function()
    flash.treesitter()
end, { desc = "Flash Treesitter" })
