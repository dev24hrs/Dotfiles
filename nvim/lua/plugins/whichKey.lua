-- Copyright (c) 2026 dev24hrs. All rights reserved.
-- The source code is released under the MIT License.
--
--- @module 'whichKey'
--- @author dev24hrs <asang24dev@gmail.com>
--- @date 2026-11-12
--- @description Which-key keybinding hints

vim.pack.add({
    { src = "https://github.com/folke/which-key.nvim" },
    { src = "https://github.com/nvim-tree/nvim-web-devicons" },
})

require("which-key").setup({
    ---@type false | "classic" | "modern" | "helix"
    preset = "modern",
})

vim.keymap.set("n", "<leader>?", function()
    require("which-key").show({ global = false })
end, { desc = "[WhichKey]: Buffer Local Keymaps" })
